#!/bin/bash
set -e

REPO="https://raw.githubusercontent.com/wwenderson/portainer/main"
WORKDIR="$HOME/wanzeller"

# 🗂️ Cria diretório de trabalho
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# 🔍 Verifica se o 'envsubst' está instalado
if ! command -v envsubst >/dev/null 2>&1; then
  echo "⚠️  O utilitário 'envsubst' não está instalado. Tentando instalar automaticamente..."
  if command -v apt >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y gettext-base
  else
    echo "❌ Instalação automática falhou. Por favor, instale manualmente com:"
    echo "   sudo apt install gettext-base"
    exit 1
  fi

  command -v envsubst >/dev/null 2>&1 || {
    echo "❌ Não foi possível instalar o 'envsubst'."
    exit 1
  }

  echo "✅ 'envsubst' instalado com sucesso!"
fi

# 1) Lê nome de usuário base
while true; do
  read -p "Informe o nome de usuário base (ex: wanzeller): " USER_NAME
  [[ "$USER_NAME" =~ ^[a-zA-Z0-9_]{3,}$ ]] && break
  echo "❌ Nome de usuário inválido. Use apenas letras, números ou underline. Mínimo 3 caracteres."
done

# 2) Lê e-mail principal
while true; do
  read -p "Informe o e-mail principal do sistema (ex: voce@dominio.com): " EMAIL
  [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && break
  echo "❌ E-mail inválido. Exemplo: seuemail@dominio.com"
done

# 3) Lê domínio base
while true; do
  read -p "Informe o domínio principal (ex: seudominio.com): " DOMAIN
  [[ "$DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && break
  echo "❌ Domínio inválido. Exemplo: seudominio.com"
done

# 4) Extrai o radical do domínio
RADICAL=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)}')

# 5) Exporta variáveis
export DOMAIN EMAIL USER_NAME RADICAL

# 7) Cria secret GLOBAL_SECRET
SECRET_NAME="GLOBAL_SECRET"
if ! docker secret inspect "$SECRET_NAME" >/dev/null 2>&1; then
  GLOBAL_SECRET=$(openssl rand -base64 32)
  echo "$GLOBAL_SECRET" | docker secret create "$SECRET_NAME" -
else
  GLOBAL_SECRET="<secret já existe>"
fi

# 8) Resumo
echo
echo "📝 Variáveis geradas:"
echo "DOMAIN        = $DOMAIN"
echo "EMAIL         = $EMAIL"
echo "USER_NAME     = $USER_NAME"
echo "RADICAL       = $RADICAL"
echo "GLOBAL_SECRET = $GLOBAL_SECRET"
read -p "⚠️  Copie e guarde em local seguro. Pressione ENTER para continuar..."


# 9) Gera wanzeller.env
cat > "$WORKDIR/.wanzeller.env" <<EOF
DOMAIN=$DOMAIN
EMAIL=$EMAIL
USER_NAME=$USER_NAME
RADICAL=$RADICAL
GLOBAL_SECRET=$GLOBAL_SECRET
EOF
echo "✅ Arquivo '.wanzeller.env' criado em $WORKDIR."

# 9.1) Garante que o .wanzeller.env será carregado no bashrc
if ! grep -q 'source "$HOME/wanzeller/.wanzeller.env"' "$HOME/.bashrc"; then
  echo '[ -f "$HOME/wanzeller/.wanzeller.env" ] && source "$HOME/wanzeller/.wanzeller.env"' >> "$HOME/.bashrc"
  echo "✅ Link para '.wanzeller.env' adicionado ao .bashrc"
fi

# 9.2) Carrega as variáveis agora mesmo
set -a
source "$WORKDIR/.wanzeller.env"
set +a

# 10) Cria redes necessárias
docker network create --driver=overlay --attachable traefik_public >/dev/null 2>&1 || true
docker network create --driver=overlay --attachable wanzeller_network >/dev/null 2>&1 || true

# 11) Deploy do Traefik
echo "🚀 Deploy Traefik..."
curl -sSL "$REPO/traefik.yaml" -o "$WORKDIR/traefik.yaml"
envsubst < "$WORKDIR/traefik.yaml" < "$WORKDIR/.wanzeller.env" > "$WORKDIR/traefik.rendered.yaml"
docker stack deploy -c "$WORKDIR/traefik.rendered.yaml" traefik

# 12) Deploy do Portainer com variáveis carregadas
echo "🚀 Deploy Portainer..."
curl -sSL "$REPO/portainer.yaml" -o "$WORKDIR/portainer.yaml"
envsubst < "$WORKDIR/portainer.yaml" < "$WORKDIR/.wanzeller.env" > "$WORKDIR/portainer.rendered.yaml"
docker stack deploy -c "$WORKDIR/portainer.rendered.yaml" portainer
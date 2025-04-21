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

  if ! command -v envsubst >/dev/null 2>&1; then
    echo "❌ Não foi possível instalar o 'envsubst'."
    exit 1
  fi

  echo "✅ 'envsubst' instalado com sucesso!"
fi

# 1) Lê nome de usuário base
while true; do
  read -p "Informe o nome de usuário base (ex: wanzeller): " USER_NAME
  if [[ "$USER_NAME" =~ ^[a-zA-Z0-9_]{3,}$ ]]; then
    break
  fi
  echo "❌ Nome de usuário inválido. Use apenas letras, números ou underline. Mínimo 3 caracteres."
  echo "   Para abortar, pressione CTRL+C."
done

# 2) Lê e-mail principal
while true; do
  read -p "Informe o e-mail principal do sistema (ex: voce@dominio.com): " EMAIL
  if [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    break
  fi
  echo "❌ E-mail inválido. Exemplo: seuemail@dominio.com"
  echo "   Para abortar, pressione CTRL+C."
done

# 3) Lê domínio base
while true; do
  read -p "Informe o domínio principal (ex: seudominio.com): " DOMAIN
  if [[ "$DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    break
  fi
  echo "❌ Domínio inválido. Exemplo: seudominio.com"
  echo "   Para abortar, pressione CTRL+C."
done

# 4) Extrai o radical do domínio
RADICAL=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)}')

# 5) Exporta variáveis
export DOMAIN EMAIL USER_NAME RADICAL

# 6) Persiste no ~/.bashrc
if ! grep -q "export DOMAIN=" ~/.bashrc; then
  {
    echo "export DOMAIN=$DOMAIN"
    echo "export EMAIL=$EMAIL"
    echo "export USER_NAME=$USER_NAME"
    echo "export RADICAL=$RADICAL"
  } >> ~/.bashrc
  echo "✅ Variáveis salvas em ~/.bashrc"
fi

# 7) Cria secret GLOBAL_SECRET
SECRET_NAME="GLOBAL_SECRET"
if ! docker secret inspect "$SECRET_NAME" >/dev/null 2>&1; then
  GLOBAL_SECRET=$(openssl rand -base64 32)
  echo "$GLOBAL_SECRET" | docker secret create "$SECRET_NAME" -
else
  GLOBAL_SECRET="<secret já existe>"
fi

# 8) Resumo e pausa
echo
echo "📝 Variáveis geradas:"
echo "DOMAIN        = $DOMAIN"
echo "EMAIL         = $EMAIL"
echo "USER_NAME     = $USER_NAME"
echo "RADICAL       = $RADICAL"
echo "GLOBAL_SECRET = $GLOBAL_SECRET"
read -p "⚠️  Copie e guarde em local seguro. Pressione ENTER para continuar..."

# 9) Gera env.wanzeller
cat > "$WORKDIR/env.wanzeller" <<EOF
DOMAIN=$DOMAIN
EMAIL=$EMAIL
USER_NAME=$USER_NAME
RADICAL=$RADICAL
GLOBAL_SECRET=$GLOBAL_SECRET
EOF
echo "✅ Arquivo 'env.wanzeller' criado em $WORKDIR."

# 10) Cria redes
docker network create --driver=overlay --attachable traefik_public >/dev/null 2>&1 || true
docker network create --driver=overlay --attachable agent_network >/dev/null 2>&1 || true
docker network create --driver=overlay --attachable wanzeller_network >/dev/null 2>&1 || true

# 11) Deploy Traefik
echo "🚀 Deploy Traefik..."
curl -sSL "$REPO/traefik.yaml" | envsubst '$EMAIL' > "$WORKDIR/traefik.yaml"
docker stack deploy -c "$WORKDIR/traefik.yaml" traefik

# 12) Deploy Portainer
echo "🚀 Deploy Portainer..."
curl -sSL "$REPO/deploy.sh" -o "$WORKDIR/deploy.sh"
chmod +x "$WORKDIR/deploy.sh"
"$WORKDIR/deploy.sh" "$DOMAIN"
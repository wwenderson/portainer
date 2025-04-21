#!/bin/bash

# Ativa modo de erro para interromper execução caso qualquer comando falhe
set -e

# Configurações básicas do repositório e diretório de trabalho
REPO="https://raw.githubusercontent.com/wwenderson/portainer/main"
WORKDIR="$HOME/wanzeller"

# Criação do diretório de trabalho
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Verifica e instala 'envsubst' se necessário
if ! command -v envsubst >/dev/null 2>&1; then
  echo "O utilitário 'envsubst' não foi encontrado. Tentando instalar automaticamente..."
  if command -v apt >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y gettext-base
  else
    echo "Falha ao instalar automaticamente. Instale manualmente com: sudo apt install gettext-base"
    exit 1
  fi

  command -v envsubst >/dev/null 2>&1 || {
    echo "Falha ao instalar 'envsubst'."
    exit 1
  }

  echo "'envsubst' instalado com sucesso."
fi

# Solicita ao usuário o nome base para uso no sistema
while true; do
  read -p "Informe o nome de usuário base (ex: wanzeller): " USER_NAME
  [[ "$USER_NAME" =~ ^[a-zA-Z0-9_]{3,}$ ]] && break
  echo "Nome inválido. Apenas letras, números e underline. Mínimo 3 caracteres."
done

# Solicita e-mail principal do sistema
while true; do
  read -p "Informe o e-mail principal do sistema (ex: voce@dominio.com): " EMAIL
  [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && break
  echo "E-mail inválido. Formato correto: usuario@dominio.com"
done

# Solicita o domínio principal
while true; do
  read -p "Informe o domínio principal (ex: seudominio.com): " DOMAIN
  [[ "$DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && break
  echo "Domínio inválido. Formato correto: dominio.com"
done

# Extrai radical (parte principal) do domínio
RADICAL=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)}')

# Exporta variáveis para ambiente
export DOMAIN EMAIL USER_NAME RADICAL

# Criação segura do secret GLOBAL_SECRET no Docker
SECRET_NAME="GLOBAL_SECRET"
if ! docker secret inspect "$SECRET_NAME" >/dev/null 2>&1; then
  GLOBAL_SECRET=$(openssl rand -base64 32)
  echo "$GLOBAL_SECRET" | docker secret create "$SECRET_NAME" -
else
  GLOBAL_SECRET="<secret já existe>"
fi

# Exibe resumo das variáveis configuradas
cat <<EOF
Variáveis configuradas:
  DOMAIN        = $DOMAIN
  EMAIL         = $EMAIL
  USER_NAME     = $USER_NAME
  RADICAL       = $RADICAL
  GLOBAL_SECRET = $GLOBAL_SECRET
EOF
read -p "Copie e guarde essas variáveis em local seguro. Pressione ENTER para continuar..."

# Cria arquivo de variáveis de ambiente
cat > "$WORKDIR/.wanzeller.env" <<EOF
DOMAIN=$DOMAIN
EMAIL=$EMAIL
USER_NAME=$USER_NAME
RADICAL=$RADICAL
GLOBAL_SECRET=$GLOBAL_SECRET
EOF
echo "Arquivo '.wanzeller.env' criado em $WORKDIR."

# Garante carregamento automático das variáveis no bash
if ! grep -q 'source "$HOME/wanzeller/.wanzeller.env"' "$HOME/.bashrc"; then
  echo '[ -f "$HOME/wanzeller/.wanzeller.env" ] && source "$HOME/wanzeller/.wanzeller.env"' >> "$HOME/.bashrc"
  echo "Inclusão automática das variáveis configurada no '.bashrc'."
fi

# Carrega variáveis imediatamente
set -a
source "$WORKDIR/.wanzeller.env"
set +a

# Criação das redes Docker necessárias (overlay)
docker network create --driver=overlay --attachable traefik_public >/dev/null 2>&1 || true
docker network create --driver=overlay --attachable wanzeller_network >/dev/null 2>&1 || true

# Deploy do Traefik
curl -sSL "$REPO/traefik.yaml" -o "$WORKDIR/traefik.yaml"
envsubst < "$WORKDIR/traefik.yaml" < "$WORKDIR/.wanzeller.env" > "$WORKDIR/traefik.rendered.yaml"
docker stack deploy -c "$WORKDIR/traefik.rendered.yaml" traefik

# Deploy do Portainer
curl -sSL "$REPO/portainer.yaml" -o "$WORKDIR/portainer.yaml"
envsubst < "$WORKDIR/portainer.yaml" < "$WORKDIR/.wanzeller.env" > "$WORKDIR/portainer.rendered.yaml"
docker stack deploy -c "$WORKDIR/portainer.rendered.yaml" portainer

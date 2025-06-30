#!/bin/bash
set -e
umask 077
trap 'echo "Script interrompido."; exit 1' INT

REPO="https://raw.githubusercontent.com/wwenderson/portainer/main"
WORKDIR="$HOME/wanzeller"

# Verificar dependências
for cmd in docker openssl awk curl grep envsubst; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Dependência '$cmd' não encontrada. Instale antes de continuar."
    exit 1
  fi
done

# Criar diretório de trabalho
mkdir -p "$WORKDIR/stack"
cd "$WORKDIR"

# Inicializar Docker Swarm (se necessário)
if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -qw active; then
  docker swarm init
fi

# Ler nome de usuário base
while true; do
  read -p "Informe o nome de usuário base (ex: wanzeller): " USUARIO
  [[ "$USUARIO" =~ ^[a-zA-Z0-9_]{3,}$ ]] && break
  echo "Nome de usuário inválido. Mínimo 3 caracteres alfanuméricos ou underline."
done

# Ler e-mail principal
while true; do
  read -p "Informe o e-mail principal (ex: voce@dominio.com): " EMAIL
  [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && break
  echo "E-mail inválido."
done

# Ler domínio base
while true; do
  read -p "Informe o domínio principal (ex: seudominio.com): " DOMINIO
  [[ "$DOMINIO" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && break
  echo "Domínio inválido."
done

# Ler variáveis do Postgres
while true; do
  read -p "Informe o usuário do Postgres (ex: admin): " POSTGRES_USER
  [[ "$POSTGRES_USER" =~ ^[a-zA-Z0-9_]{3,}$ ]] && break
  echo "Usuário do Postgres inválido."
done

while true; do
  read -s -p "Informe a senha do Postgres: " POSTGRES_PASSWORD
  echo
  [[ -n "$POSTGRES_PASSWORD" ]] && break
  echo "Senha não pode ser vazia."
done

while true; do
  read -p "Informe o nome do banco de dados (ex: banco): " POSTGRES_DB
  [[ "$POSTGRES_DB" =~ ^[a-zA-Z0-9_]{3,}$ ]] && break
  echo "Nome do banco inválido."
done

# Extrair radical do domínio
RADICAL=$(echo "$DOMINIO" | awk -F. '{print $(NF-1)}')

# Exportar variáveis para envsubst
export DOMINIO EMAIL USUARIO RADICAL POSTGRES_USER POSTGRES_PASSWORD POSTGRES_DB

# Gerar arquivo de ambiente
cat > "$WORKDIR/stack/.wanzeller.env" <<EOF
DOMINIO=$DOMINIO
EMAIL=$EMAIL
USUARIO=$USUARIO
RADICAL=$RADICAL
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=$POSTGRES_DB
EOF

# Criar redes overlay necessárias
for net in traefik_public agent_network wanzeller_network; do
  docker network inspect "$net" &>/dev/null || \
    docker network create --driver overlay --attachable "$net"
done

# Baixar arquivos YAML atualizados do repositório
for stack in traefik portainer postgres pgadmin; do
  curl -fSL "$REPO/stack/$stack.yaml" -o "$WORKDIR/stack/$stack.yaml" \
    || { echo "Erro ao baixar $stack.yaml"; exit 1; }
done

# Deploy das stacks usando envsubst para interpolar variáveis
for stack in traefik portainer postgres pgadmin; do
  envsubst < "$WORKDIR/stack/$stack.yaml" | \
    docker stack deploy -c - "$stack"
done

echo "Script concluído com sucesso."
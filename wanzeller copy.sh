#!/bin/bash
set -e

REPO="https://raw.githubusercontent.com/wwenderson/portainer/main"
WORKDIR="$HOME/wanzeller"

# Verifica dependências
echo "🔎 Verificando dependências necessárias..."
for cmd in docker openssl awk curl grep; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ A dependência '$cmd' não foi encontrada. Por favor, instale antes de continuar."
    exit 1
  fi
done
echo "✅ Todas as dependências estão instaladas."

# Cria diretório de trabalho
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Inicializa Swarm (se necessário)
if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -qw active; then
  echo "Inicializando Docker Swarm..."
  docker swarm init
else
  echo "Docker Swarm já está ativo."
fi

# Lê nome de usuário base
while true; do
  read -p "Informe o nome de usuário base (ex: wanzeller): " USUARIO
  [[ "$USUARIO" =~ ^[a-zA-Z0-9_]{3,}$ ]] && break
  echo "❌ Nome de usuário inválido. Use apenas letras, números ou underline. Mínimo 3 caracteres."
done

# Lê e-mail principal
while true; do
  read -p "Informe o e-mail principal do sistema (ex: voce@dominio.com): " EMAIL
  [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && break
  echo "❌ E-mail inválido. Exemplo: seuemail@dominio.com"
done

# Lê domínio base
while true; do
  read -p "Informe o domínio principal (ex: seudominio.com): " DOMINIO
  [[ "$DOMINIO" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && break
  echo "❌ Domínio inválido. Exemplo: seudominio.com"
done

# Extrai radical do domínio
RADICAL=$(echo "$DOMINIO" | awk -F. '{print $(NF-1)}')

# Exporta variáveis
export DOMINIO EMAIL USUARIO RADICAL

# Cria secret GLOBAL_SECRET
SECRET_NAME="GLOBAL_SECRET"
if ! docker secret inspect "$SECRET_NAME" >/dev/null 2>&1; then
  GLOBAL_SECRET=$(openssl rand -base64 32)
  echo "$GLOBAL_SECRET" | docker secret create "$SECRET_NAME" -
  echo "Secret '$SECRET_NAME' criado."
else
  echo "Secret '$SECRET_NAME' já existe."
fi

# Cria arquivo de variáveis de ambiente
cat > "$WORKDIR/stack/.wanzeller.env" <<EOF
DOMINIO=$DOMINIO
EMAIL=$EMAIL
USUARIO=$USUARIO
RADICAL=$RADICAL
EOF
echo "Arquivo '.wanzeller.env' criado em $WORKDIR/stack."

# Cria redes necessárias
for net in traefik_public wanzeller_network; do
  if ! docker network inspect "$net" >/dev/null 2>&1; then
    docker network create --driver=overlay --attachable "$net"
    echo "Rede '$net' criada."
  else
    echo "Rede '$net' já existe."
  fi
done


# Baixa e faz deploy dos stacks
for stack in traefik portainer; do
  mkdir -p "$WORKDIR/stack"
  echo "⬇️ Baixando configuração do $stack..."
  curl -sSL "$REPO/stack/$stack.yaml" -o "$WORKDIR/stack/$stack.yaml"
done

for stack in traefik portainer; do
  echo "🚀 Deploy $stack..."
  docker compose -f "$WORKDIR/stack/$stack.yaml" --env-file "$WORKDIR/stack/.wanzeller.env" config | docker stack deploy -c - "$stack"
done


echo "✅ Script concluído com sucesso."
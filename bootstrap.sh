#!/bin/bash
set -e

REPO="https://raw.githubusercontent.com/wwenderson/portainer/main"

# Lê domínio (primeiro argumento ou prompt)
if [ -n "$1" ]; then
  DOMAIN=$1
else
  read -p "Informe o domínio (ex: portainer.seudominio.com): " DOMAIN
fi

# Lê e‑mail ACME (segundo argumento ou prompt)
if [ -n "$2" ]; then
  EMAIL=$2
else
  read -p "Informe o e‑mail para Let's Encrypt: " EMAIL
fi

# Certifica-se de que o script tem permissão de execução
chmod +x "$0"

# Inicializa Swarm e cria redes overlay
docker swarm init >/dev/null 2>&1 || true
docker network create --driver=overlay --attachable traefik_public >/dev/null 2>&1 || true
docker network create --driver=overlay --attachable agent_network    >/dev/null 2>&1 || true

# Baixa e prepara o Traefik
curl -sSL "$REPO/traefik.yaml" | \
  TRAEFIK_EMAIL="$EMAIL" envsubst '$TRAEFIK_EMAIL' > traefik-stack.yml

# Deploy do Traefik
docker stack deploy -c traefik-stack.yml traefik

# Aguarda Traefik subir
for i in {1..10}; do
  if docker service ls --filter name=traefik_traefik --format '{{.Replicas}}' | grep -q "^1/1$"; then
    break
  fi
  sleep 3
done

# Baixa o deploy.sh e já torna executável
curl -sSL "$REPO/deploy.sh" -o deploy.sh
chmod +x deploy.sh

# Executa o deploy do Portainer
./deploy.sh "$DOMAIN"
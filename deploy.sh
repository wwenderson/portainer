#!/bin/bash
set -e

DOMAIN=$1
if [ -z "$DOMAIN" ]; then
  echo "Uso: deploy.sh <DOMÍNIO>"
  echo "Exemplo: ./deploy.sh seudominio.com"
  exit 1
fi

# Define o repositório onde está o portainer.yaml
REPO="https://raw.githubusercontent.com/wwenderson/portainer/main"

# Exporta o domínio para o envsubst
export DOMAIN

# Baixa o portainer.yaml
echo "🔽 Baixando portainer.yaml do repositório..."
curl -fsSL "$REPO/portainer.yaml" -o portainer.yaml

# Verifica se o arquivo foi realmente baixado
if [ ! -s portainer.yaml ]; then
  echo "❌ Erro: não foi possível baixar portainer.yaml ou o arquivo está vazio."
  exit 1
fi

# Substitui a variável DOMAIN e envia para o docker stack deploy
echo "🚀 Fazendo deploy do Portainer..."
envsubst '$DOMAIN' < portainer.yaml | docker stack deploy -c - portainer
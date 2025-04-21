#!/bin/bash
set -e

# Verifica se a variável DOMAIN foi passada corretamente
if [ -z "$DOMAIN" ]; then
  echo "❌ Erro: variável DOMAIN não encontrada no ambiente."
  exit 1
fi

# Exporta todas as variáveis necessárias para o envsubst
export DOMAIN EMAIL USER_NAME RADICAL

# Define o repositório e diretório de trabalho
REPO="https://raw.githubusercontent.com/wwenderson/portainer/main"
WORKDIR="$HOME/wanzeller"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Baixa o arquivo portainer.yaml
echo "🔽 Baixando portainer.yaml do repositório..."
curl -fsSL "$REPO/portainer.yaml" -o portainer.yaml

# Verifica se o arquivo foi realmente baixado
if [ ! -s portainer.yaml ]; then
  echo "❌ Erro: não foi possível baixar portainer.yaml ou o arquivo está vazio."
  exit 1
fi

# Substitui todas as variáveis e faz o deploy
echo "🚀 Fazendo deploy do Portainer..."
envsubst < portainer.yaml | docker stack deploy -c - portainer
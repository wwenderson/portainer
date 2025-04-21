#!/bin/bash
set -e

DOMAIN=$1
if [ -z "$DOMAIN" ]; then
  echo "Uso: deploy.sh <DOMÍNIO>"
  echo "Exemplo: ./deploy.sh seudominio.com"
  exit 1
fi

# Exporta o domínio para o envsubst
export DOMAIN

# Substitui a variável DOMAIN e já envia o resultado para o docker
envsubst '$DOMAIN' < portainer.yaml | docker stack deploy -c - portainer
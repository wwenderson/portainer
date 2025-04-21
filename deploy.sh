#!/bin/bash
set -e

DOMAIN=$1
if [ -z "$DOMAIN" ]; then
  echo "Usage: deploy.sh <PORTAINER_DOMAIN>"
  exit 1
fi

export PORTAINER_DOMAIN=$DOMAIN

envsubst < portainer.yaml > portainer-compose.yml
docker stack deploy -c portainer-compose.yml portainer
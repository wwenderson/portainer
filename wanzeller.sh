#!/bin/bash
set -e  # Encerra imediatamente se qualquer comando retornar erro
set -o pipefail  # Encerra o script se qualquer comando em um pipeline falhar
readonly REPO="https://raw.githubusercontent.com/wwenderson/portainer/main"  # URL do repositório contendo os arquivos YAML
readonly WORKDIR="$HOME/wanzeller"  # Diretório de trabalho local
umask 077  # Garante permissões seguras para os arquivos criados
trap 'echo "Script interrompido."; exit 1' INT  # Captura interrupção manual (Ctrl+C)

# Verifica se todas as dependências estão instaladas
for cmd in docker openssl awk curl grep; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ A dependência '$cmd' não foi encontrada. Instale antes de continuar."
    exit 1
  fi
done

# Verifica e instala o 'envsubst' caso não esteja presente
if ! command -v envsubst >/dev/null 2>&1; then
  echo "Instalando 'envsubst' (pacote gettext)..."
  sudo apt-get update -qq && sudo apt-get install -y gettext
  if command -v envsubst >/dev/null 2>&1; then
    echo "'envsubst' instalado com sucesso."
  else
    echo "Falha ao instalar 'envsubst'."
    exit 1
  fi
fi

# Inicializa o Docker Swarm se ainda não estiver ativo
if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -qw active; then
  docker swarm init
fi

# Verifica se já existem stacks ativas (traefik, portainer, postgres, pgadmin)
# Se existirem, pergunta ao usuário se deseja removê-las antes do novo deploy
STACKS=("traefik" "portainer" "postgres" "pgadmin")
DEPLOY_EXISTENTE=()

for stack in "${STACKS[@]}"; do
  # Verifica se a stack atual já está ativa
  if docker stack ls --format '{{.Name}}' | grep -q "^${stack}$"; then
    DEPLOY_EXISTENTE+=("$stack")
  fi
done

# Se houver pelo menos uma stack ativa, solicitar confirmação do usuário para remover todas
if [ ${#DEPLOY_EXISTENTE[@]} -gt 0 ]; then
  echo "⚠️ As seguintes stacks já estão ativas: ${DEPLOY_EXISTENTE[*]}"
  read -p "Deseja remover todas e reinstalar? (s/N): " RESPOSTA
  if [[ "$RESPOSTA" =~ ^[sS](im)?$ ]]; then
    # Executa a remoção das stacks listadas com uma pausa de 5 segundos entre cada uma
    for stack in "${DEPLOY_EXISTENTE[@]}"; do
      echo "Removendo stack '$stack'..."
      docker stack rm "$stack"
      sleep 5
    done
    echo "⚠️ As stacks foram removidas."
    read -p "ATENÇÃO: Deseja também remover definitivamente os volumes 'portainer_data' e 'pgadmin_data'? (s/N): " RESPOSTA_VOLUMES
    if [[ "$RESPOSTA_VOLUMES" =~ ^[sS](im)?$ ]]; then
      echo "Removendo volumes persistentes de Portainer e pgAdmin..."
      docker volume rm portainer_data pgadmin_data &>/dev/null || true
      echo "Volumes removidos."
      REMOVER_VOLUMES=true
    else
      echo "Volumes mantidos."
      REMOVER_VOLUMES=false
    fi
  else
    echo "Stacks mantidas. Continuando com o script..."
  fi
fi

solicitar_usuario() {
  while true; do
    read -p "Informe o nome de usuário base (ex: wanzeller): " USUARIO
    [[ "$USUARIO" =~ ^[a-zA-Z0-9_]{3,}$ ]] && break
    echo "Nome de usuário inválido. Mínimo 3 caracteres alfanuméricos ou underline."
  done
}

solicitar_email() {
  while true; do
    read -p "Informe o e-mail principal (ex: voce@dominio.com): " EMAIL
    [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && break
    echo "E-mail inválido."
  done
}

solicitar_dominio() {
  while true; do
    read -p "Informe o domínio principal (ex: seudominio.com): " DOMINIO
    [[ "$DOMINIO" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,63}$ ]] && break
    echo "Domínio inválido."
  done
}

solicitar_credenciais_db() {
  while true; do
    read -p "Informe o usuário do Postgres (ex: admin): " POSTGRES_USER
    [[ "$POSTGRES_USER" =~ ^[a-zA-Z0-9_]{3,}$ ]] && break
    echo "Usuário do Postgres inválido."
  done

  while true; do
    read -s -p "Informe a senha do banco de dados: " POSTGRES_PASSWORD
    echo
    if [[ -z "$POSTGRES_PASSWORD" ]]; then
      echo "Senha não pode ser vazia."
    elif [[ "$POSTGRES_PASSWORD" =~ [\$\\\"\'\`] ]]; then
      echo "A senha não pode conter os caracteres especiais: \$ \\ \" ' \`"
    else
      break
    fi
  done

  while true; do
    read -p "Informe o nome do banco de dados (ex: banco): " POSTGRES_DB
    [[ "$POSTGRES_DB" =~ ^[a-zA-Z0-9_]{3,}$ ]] && break
    echo "Nome do banco inválido."
  done
}

# Chama as funções para solicitar as informações do usuário
solicitar_usuario
solicitar_email
solicitar_dominio
solicitar_credenciais_db

# Exporta variáveis de ambiente para uso com envsubst
export DOMINIO EMAIL USUARIO POSTGRES_USER POSTGRES_PASSWORD POSTGRES_DB  # Necessário para envsubst

# Cria o diretório de trabalho para armazenar os arquivos YAML e variáveis
mkdir -p "$WORKDIR/stack"
cd "$WORKDIR"

# Cria arquivo .env com as variáveis para referência futura
cat > "$WORKDIR/stack/.wanzeller.env" <<EOF
DOMINIO=$DOMINIO
EMAIL=$EMAIL
USUARIO=$USUARIO
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=$POSTGRES_DB
EOF

# Cria redes overlay necessárias caso ainda não existam
for net in traefik_public agent_network wanzeller_network; do
  docker network inspect "$net" &>/dev/null || \
    docker network create --driver overlay --attachable "$net"
done

# Cria volumes externos necessários caso tenham sido mantidos
if [ "$REMOVER_VOLUMES" != true ]; then
  for vol in pgadmin_data portainer_data postgres_data traefik_certificates; do
    docker volume inspect "$vol" &>/dev/null || docker volume create "$vol"
  done
fi

echo "🧹 Removendo volumes persistentes de Portainer e pgAdmin (se existirem)..."
docker volume rm portainer_data pgadmin_data &>/dev/null || true
echo "Volumes removidos ou não existentes."

# Baixa os arquivos YAML correspondentes às stacks
for stack in traefik portainer postgres pgadmin; do
  curl -fSL "$REPO/stack/$stack.yaml" -o "$WORKDIR/stack/$stack.yaml" \
    || { echo "Erro ao baixar $stack.yaml"; exit 1; }
done

# Substitui variáveis com envsubst e realiza o deploy das stacks
for stack in traefik portainer postgres pgadmin; do
  envsubst '${DOMINIO} ${EMAIL} ${USUARIO} ${POSTGRES_USER} ${POSTGRES_PASSWORD} ${POSTGRES_DB}' < "$WORKDIR/stack/$stack.yaml" | \
    docker stack deploy --detach=true --with-registry-auth -c - "$stack" || { echo "❌ Falha ao fazer deploy de $stack."; exit 1; }
done

# Confirma finalização do processo
echo "✅ Todas as operações foram concluídas sem erros."
echo "Script concluído com sucesso."
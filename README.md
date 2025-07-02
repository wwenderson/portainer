# Portainer Stack Completa (Portainer + Traefik + PostgreSQL + PGAdmin)

Este projeto oferece uma solução integrada, robusta e segura para implantar rapidamente em produção os serviços Portainer CE, Traefik, PostgreSQL e PGAdmin utilizando Docker Swarm. Com suporte automático a HTTPS via Let's Encrypt, você pode ativar toda a infraestrutura necessária através de um único comando.

---

## Funcionalidades Principais

- Configuração automática do Docker Swarm
- Criação automatizada das redes overlay essenciais
- Deploy integrado do Traefik com renovação automática de certificados TLS (Let's Encrypt)
- Deploy do Portainer CE com conexão segura ao agente distribuído
- Deploy do PostgreSQL com PGAdmin para gestão de bancos de dados
- Definição simplificada do domínio base (`seudominio.com`)
- Gerenciamento centralizado por script (`wanzeller.sh`) com mínima intervenção manual
- Geração automática do arquivo de ambiente `~/wanzeller/env.wanzeller`

---

## Requisitos para Instalação

- Servidor Linux (Ubuntu 20.04/22.04 recomendado) ou macOS
- Docker CE versão 20.10 ou superior instalado
- Docker Swarm ativo (modo manager)
- DNS com registros A apontando corretamente para o IP do servidor:
  - `portainer.seudominio.com`
  - `pgadmin.seudominio.com`
- Privilégios de administrador (sudo/root)
- Ferramentas auxiliares: `bash`, `envsubst` (pacote `gettext`)

---

## Configuração inicial do Docker Swarm

Execute no terminal para ativar o Docker Swarm:
```bash
docker swarm init
```
---

## Instalação Automatizada

Execute diretamente no terminal o seguinte comando:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wwenderson/portainer/main/wanzeller.sh) && rm -rf .git
```

### O que acontece durante a instalação?

- Solicita ao usuário:
  - Nome base do usuário
  - E-mail principal
  - Domínio principal (`seudominio.com`)
- Cria o arquivo `~/wanzeller/env.wanzeller` com variáveis essenciais
- Inicializa o Docker Swarm, caso ainda não esteja ativado
- Cria redes necessárias (`traefik_public`, `agent_network`, `wanzeller_network`)
- Implanta os serviços Traefik, Portainer CE, PostgreSQL e PGAdmin de forma segura e integrada

---

## Acessando os Serviços Implantados

Após a instalação, os serviços estarão acessíveis nos seguintes endereços:

- **Portainer CE:**
```
  URL: https://portainer.seudominio.com
```

- **PGAdmin (Gestão do PostgreSQL):**
```
  URL: https://pgadmin.seudominio.com
  Usuário: admin@seudominio.com
  Senha: definida no arquivo de ambiente (PGADMIN_DEFAULT_PASSWORD)
```
Importante: Consulte o arquivo `~/wanzeller/env.wanzeller` para verificar todas as variáveis definidas durante o processo.

---

## Estrutura dos Arquivos Criados

Todos os arquivos ficam organizados no diretório `~/wanzeller`:

- `wanzeller.sh`: Script principal de instalação automatizada
- `deploy.sh`: Script auxiliar para deploys adicionais
- `traefik.yaml`: Configuração detalhada do Traefik
- `portainer.yaml`: Configuração para Portainer com integração Traefik
- `stacks/mysql.yaml`: Exemplo adicional com MySQL e phpMyAdmin
- `stacks/postgres.yaml`: Stack completa de PostgreSQL com PGAdmin
- `.env.wanzeller`: Variáveis essenciais definidas automaticamente
- `README.md`: Este manual de referência técnica

---

## Segurança e Melhores Práticas

- Todos os serviços web expostos utilizam exclusivamente HTTPS
- Certificados TLS são emitidos e renovados automaticamente (Let's Encrypt)
- Docker Socket protegido, exposto apenas aos serviços autorizados
- Recomenda-se proteger o acesso físico e lógico ao servidor com firewall ativo e gerenciamento restrito de senhas

---

## Como Adicionar Novas Stacks no Portainer

No Portainer, use a opção de criação de stacks a partir do Git:

- Repositório: https://github.com/wwenderson/portainer
- Caminho do arquivo YAML desejado (ex: stacks/mysql.yaml)
- Variáveis necessárias:
  - DOMINIO (ex: seudominio.com)
  - USUARIO (seu usuário)
  - EMAIL (ex: seunome@seudominio.com)

---

## Ambiente Validado

Este projeto foi amplamente testado nas seguintes configurações:

- Ubuntu 20.04 e 22.04 LTS
- Docker CE 20.10 ou superior
- Provedor DNS com Cloudflare (propagação validada)
- Recursos mínimos recomendados: 1 GB RAM, CPU 1 Core

---

## Autor e Suporte

**Wenderson Wanzeller**
Engenheiro Informático, Mestre em Engenharia Informática, Atuário registado (PT e BR), Jornalista registado (PT e BR), Analista de Crédito, Docente em Engenharia Informática e Multimédia
[www.wendersonwanzeller.com](https://www.wendersonwanzeller.com) 
[GitHub](https://github.com/wwenderson)
# Portainer Stack All-in-One (Portainer + Traefik + Postgres + PGAdmin)

Este projeto fornece uma instalação **automática e pronta para produção** do Portainer CE, do Traefik, do Postgres e do PGAdmin, com suporte a HTTPS via Let's Encrypt, usando Docker Swarm. Todo o processo é feito com **um único comando**, sem necessidade de clonar repositório nem configurar permissões manualmente.

---

## ✅ Funcionalidades

- Criação automática das redes overlay necessárias
- Deploy completo do Traefik com HTTPS automático via Let's Encrypt
- Deploy do Portainer com conexão ao agente distribuído
- Definição do domínio base (`seudominio.com`) usada em todas as stacks
- Tudo controlado por script (`bootstrap.sh`) com interação mínima
- Geração de arquivo `~/wanzeller/env.wanzeller` com todas as variáveis importantes
- Exibição em tela de todas as variáveis com pausa para cópia manual

---

## 📦 Requisitos

1. Servidor com Docker instalado (versão 20.10 ou superior)
2. Docker Swarm ativado (modo manager) – veja instruções abaixo
3. Acesso root (ou permissão sudo) para gerenciamento do Docker
4. DNS configurado com um A record apontando `portainer.seudominio.com` e `pgadmin.seudominio.com`para o IP do servidor
5. bash (Linux/macOS) ou WSL (Windows)
6. `envsubst` (disponível via pacote `gettext`)

---

## ⚙️ Ativação do Docker Swarm

Antes de executar a instalação, o Docker Swarm deve estar ativado no servidor.

Se o Swarm ainda não estiver ativo, execute o comando abaixo **no terminal**:

```bash
docker swarm init
```

---

## 🚀 Instalação automática

Execute diretamente no terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wwenderson/portainer/main/wanzeller.sh && rm -rf .git)
```

> **Nota:** O script também realizará o deploy do Postgres e do PGAdmin, ambos expostos via Traefik.

## 🧭 O que este comando faz

1. Solicita:
   - Usuário base
   - E-mail principal
   - Domínio base (ex: `seudominio.com`)
2. Extrai o `RADICAL` do domínio para usar como nome padrão de base de dados
3. Gera o arquivo `~/wanzeller/env.wanzeller` com as variáveis principais
4. Inicializa o Docker Swarm (`docker swarm init`)
5. Cria as redes `traefik_public`, `agent_network` e `wanzeller_network`
6. Realiza o deploy completo do Traefik (com HTTPS e painel)
7. Realiza o deploy do Portainer já exposto em `portainer.${DOMAIN}` via Traefik
8. Realiza o deploy do Postgres e do PGAdmin expostos via Traefik (`pgadmin.${DOMAIN}`)

---

## 🌐 Acesso final

Após a conclusão, o Portainer estará disponível em:

```
https://portainer.seudominio.com
```

Você também poderá adicionar outras stacks com domínios como:

- `https://mysql.seudominio.com`
- `https://phpmyadmin.seudominio.com`

Como acessar o PGAdmin:

```
https://pgadmin.seudominio.com

Login: admin@seudominio.com
Senha: definida na variável PGADMIN_DEFAULT_PASSWORD
```

Usando `${DOMAIN}`, `${RADICAL}`, `${USER_NAME}` nas suas definições.

---

## 📁 Estrutura dos arquivos utilizados
Todos os arquivos ficam organizados dentro da pasta `~/wanzeller`:

- `bootstrap.sh` – script principal da instalação automatizada
- `deploy.sh` – realiza o deploy do Portainer
- `traefik.yaml` – configuração do Traefik com HTTPS via Let's Encrypt
- `portainer.yaml` – configuração do Portainer + Agent com labels para Traefik
- `stacks/mysql.yaml` – exemplo de stack adicional (MySQL + phpMyAdmin)
- `stacks/postgres.yaml` – stack de exemplo do Postgres + PGAdmin
- `.env.wanzeller` – arquivo gerado com todas as variáveis
- `README.md` – este manual de instalação

---

## 🧪 Testado em

- Ubuntu 20.04 / 22.04 LTS
- Docker 20.10+
- Cloudflare (DNS A record com propagação válida)
- VPS com pelo menos 1 GB de RAM

---

## 🔐 Segurança

- O Traefik emite e renova automaticamente certificados TLS com Let's Encrypt
- O acesso ao Portainer é exposto apenas via HTTPS, com domínio personalizado
- O Docker Socket é exposto somente aos serviços autorizados (Traefik e Agent)

---

## 📦 Importar stacks adicionais

Você pode importar novas stacks diretamente no Portainer via Git, usando:

- **URL do repositório:** `https://github.com/wwenderson/portainer`
- **Caminho do arquivo:** `stacks/mysql.yaml` (ou qualquer outro `.yaml`)
- **Variáveis de ambiente esperadas:**
  - `DOMAIN`
  - `USER_NAME`
  - `RADICAL`

---

## 👨‍💻 Autor

**Wenderson Wanzeller**  
Mestre em Engenharia de Informática  
[www.wendersonwanzeller.com](https://www.wendersonwanzeller.com)  
[https://github.com/wwenderson](https://github.com/wwenderson)

---

## 🆓 Licença

Este projeto é livre, gratuito e de código aberto.  
Você pode reutilizar, modificar e redistribuir, desde que **mantenha os créditos ao autor**.

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
- Extrai automaticamente um radical do domínio para uso em banco de dados
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

> **Importante:** Consulte o arquivo `~/wanzeller/env.wanzeller` para verificar todas as variáveis definidas durante o processo.

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

- Repositório: `https://github.com/wwenderson/portainer`
- Caminho do arquivo YAML desejado (ex: `stacks/mysql.yaml`)
- Variáveis necessárias:
  - `DOMAIN` (ex: seudominio.com)
  - `USER_NAME` (seu usuário)
  - `RADICAL` (gerado automaticamente pelo script)

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

---

## Licença

Este projeto é distribuído sob licença livre. Fique à vontade para reutilizar, modificar e redistribuir, mantendo obrigatoriamente os créditos ao autor original.
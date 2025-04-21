# Portainer Stack All-in-One (Portainer + Traefik)

Este projeto fornece uma instalação **automática e pronta para produção** do Portainer CE e do Traefik, com suporte a HTTPS via Let's Encrypt, usando Docker Swarm. Todo o processo é feito com **um único comando**, sem necessidade de clonar repositório nem configurar permissões manualmente.

---

## ✅ Funcionalidades

- Instalação do Docker Swarm (caso ainda não esteja inicializado)
- Criação automática das redes overlay necessárias
- Deploy completo do Traefik com HTTPS automático via Let's Encrypt
- Deploy do Portainer com conexão ao agente distribuído
- Definição do domínio base (`seudominio.com`) usada em todas as stacks
- Armazenamento seguro de uma `GLOBAL_SECRET` compartilhada via Docker Secret
- Tudo controlado por script (`bootstrap.sh`) com interação mínima
- Geração de arquivo `env.generated` com todas as variáveis importantes
- Exibição em tela de todas as variáveis com pausa para cópia manual

---

## 📦 Requisitos

1. Servidor com Docker instalado (versão 20.10 ou superior)
2. Acesso root (ou permissão sudo) para gerenciamento do Docker
3. DNS configurado com um A record apontando `portainer.seudominio.com` para o IP do servidor
4. bash (Linux/macOS) ou WSL (Windows)
5. `envsubst` (disponível via pacote `gettext`)

---

## 🚀 Instalação automática

Execute diretamente no terminal:

```bash
curl -sSL https://raw.githubusercontent.com/wwenderson/portainer/main/bootstrap.sh | bash
```

---

## 🧭 O que este comando faz

1. Solicita:
   - Usuário base
   - E-mail principal
   - Domínio base (ex: `seudominio.com`)
2. Extrai o `RADICAL` do domínio para usar como nome padrão de base de dados
3. Cria automaticamente uma `GLOBAL_SECRET` para uso seguro em todas as stacks
4. Gera o arquivo `env.generated` com as variáveis principais
5. Inicializa o Docker Swarm (`docker swarm init`)
6. Cria as redes `traefik_public`, `agent_network` e `wanzeller_network`
7. Realiza o deploy completo do Traefik (com HTTPS e painel)
8. Realiza o deploy do Portainer já exposto em `portainer.${DOMAIN}` via Traefik

---

## 🌐 Acesso final

Após a conclusão, o Portainer estará disponível em:

```
https://portainer.seudominio.com
```

Você também poderá adicionar outras stacks com domínios como:

- `https://mysql.seudominio.com`
- `https://api.seudominio.com`

Usando `${DOMAIN}`, `${RADICAL}`, `${USER_NAME}` e o secret `GLOBAL_SECRET` nas suas definições.

---

## 📁 Estrutura dos arquivos utilizados

- `bootstrap.sh` – script principal da instalação automatizada
- `deploy.sh` – realiza o deploy do Portainer
- `traefik.yaml` – configuração do Traefik com HTTPS via Let's Encrypt
- `portainer.yaml` – configuração do Portainer + Agent com labels para Traefik
- `stacks/mysql.yaml` – exemplo de stack adicional (MySQL + phpMyAdmin)
- `env.generated` – arquivo gerado com todas as variáveis (não requer source)
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
- A senha gerada como `GLOBAL_SECRET` é única por instalação e usada em todas as stacks via Docker Secrets

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

---
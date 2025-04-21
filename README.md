# Portainer Stack All-in-One (Portainer + Traefik)

Este projeto fornece uma instalação **automática e pronta para produção** do Portainer CE e do Traefik, com suporte a HTTPS via Let's Encrypt, usando Docker Swarm. Todo o processo é feito com **um único comando**, sem necessidade de clonar repositório nem configurar permissões manualmente.

---

## ✅ Funcionalidades

- Instalação do Docker Swarm (caso ainda não esteja inicializado)
- Criação automática das redes overlay necessárias
- Deploy completo do Traefik com HTTPS automático via Let's Encrypt
- Deploy do Portainer com conexão ao agente distribuído
- Configuração de domínio personalizada
- Uso de e-mail para geração automática dos certificados TLS
- Tudo controlado por script (`bootstrap.sh`) com interação mínima

---

## 📦 Requisitos

1. Servidor com Docker instalado (versão 20.10 ou superior)
2. Acesso root (ou permissão sudo) para gerenciamento de Docker
3. DNS configurado com um A record apontando `portainer.seudominio.com` para o IP do servidor
4. bash (Linux/macOS) ou WSL (Windows)
5. envsubst (disponível via pacote `gettext`)

---

## 🚀 Instalação automática

Substitua os valores abaixo pelo seu domínio e e-mail, e execute:

```bash
curl -sSL https://raw.githubusercontent.com/wwenderson/portainer/main/bootstrap.sh | bash -s -- portainer.seudominio.com seu_email@dominio.com
```

---

## 🔧 O que acontece por trás

1. Inicializa o Docker Swarm (`docker swarm init`)
2. Cria as redes overlay `traefik_public` e `agent_network` (se ainda não existirem)
3. Baixa o arquivo `traefik.yaml` e insere o e-mail informado (para Let's Encrypt)
4. Faz o deploy do Traefik com HTTPS, dashboard e redirecionamento HTTP → HTTPS
5. Aguarda o Traefik estar disponível (`1/1 replicas`)
6. Baixa o arquivo `portainer.yaml` e o script `deploy.sh`
7. Executa o deploy do Portainer com o domínio fornecido
8. Portainer é exposto automaticamente via Traefik com certificado válido

---

## 🌐 Acesso final

Após a conclusão, o Portainer estará disponível em:

```
https://portainer.seudominio.com
```

---

## 📁 Estrutura dos arquivos utilizados

- `bootstrap.sh` – script principal de instalação automatizada
- `deploy.sh` – usado internamente para aplicar o stack do Portainer
- `traefik.yaml` – definição do serviço Traefik com suporte a TLS
- `portainer.yaml` – definição do Portainer + Agent com labels para Traefik
- `README.md` – este manual de instalação

---

## 🧪 Testado em

- Ubuntu 20.04 / 22.04 LTS
- Docker 20.10+
- Cloudflare (DNS A record com propagação válida)
- VPS com pelo menos 1 GB de RAM

---

## 🔐 Segurança

- O Traefik é configurado para emitir e renovar automaticamente certificados TLS usando Let's Encrypt
- O Portainer fica exposto apenas via HTTPS no domínio fornecido
- O Docker Socket é acessado apenas pelos containers autorizados (Traefik e Portainer Agent)

---

## ❓ Suporte

Caso tenha dúvidas ou precise de ajuda:

- Crie uma issue no repositório:  
  https://github.com/wwenderson/portainer

---

## 👨‍💻 Autor

**Wenderson Wanzeller**  
Mestre em Engenharia de Inmformática 
https://github.com/wwenderson

---

## 🆓 Licença

Este projeto é livre, gratuito e de código aberto.  
Você pode reutilizar, modificar e redistribuir, desde que **mantenha os créditos ao autor**.

---
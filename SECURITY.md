# Security Policy

## Supported Use

This repository is intended as a self-hosted n8n automation stack. Do not expose the editor or MCP mutation tools directly to the internet without authentication, TLS, monitoring, and a least-privilege access model.

## Secrets

- Never commit `.env`, API keys, exported credentials, or Terraform variable files.
- Keep `N8N_ENCRYPTION_KEY` stable and backed up.
- Use scoped n8n API keys where your plan supports API scopes.
- Treat MCP clients as privileged automation because they can create, update, and delete workflows and credentials.
- Keep `.env.production` off git and restrict its file permissions on the server.
- Keep files in `secrets/` off git and restrict them to server administrators.

## Hardening Checklist

- Pin `N8N_IMAGE`, `POSTGRES_IMAGE`, and `REDIS_IMAGE` to tested versions for production.
- Put n8n behind TLS and SSO or another strong identity layer.
- Limit who can create or edit workflows.
- Keep Postgres and Redis off public networks.
- Store Terraform state in an encrypted backend for team use.
- Rotate API keys and runner tokens regularly.
- Review workflow exports before applying Terraform changes.
- Test backups and restores before relying on them in production.
- Prefer the Caddy reverse-proxy profile when exposing n8n outside localhost.
- Run production with `docker-compose.prod.yml` and `docker-compose.proxy.yml`, not the local override file.
- Do not publish Postgres, Redis, or the Python runner ports to the internet.
- Run `scripts/preflight-production.ps1` before production startup.
- Use Caddy basic auth or replace it with a stronger SSO-aware reverse proxy before public exposure.
- Configure the Caddy username in `.env.production` with `CADDY_BASIC_AUTH_USER`; generate the password hash with `scripts/new-production-secrets.ps1`.

## Reporting

Report security issues privately to the repository owner. Do not open public issues with live secrets, tokens, workflow exports containing secrets, or exploit details.

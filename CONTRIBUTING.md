# Contributing

Thank you for contributing. This repository is security-sensitive because it manages n8n workflows, credentials, API keys, and deployment automation.

## Rules

- Do not commit `.env`, `.env.production`, `secrets/`, backups, credential exports, Terraform state, or `.tfvars`.
- Do not include real API keys, passwords, webhook secrets, or credential payloads in issues or pull requests.
- Use pull requests for changes. Direct pushes to `main` should be disabled in GitHub branch protection.
- Keep changes focused. Avoid mixing infrastructure, workflow, and documentation changes unless they are required together.
- Update `README.md` or `SECURITY.md` when changing deployment, secret, backup, or production behavior.

## Local Checks

Run the checks that apply to your change:

```powershell
docker compose config --quiet
docker compose --env-file .env.production.example -f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.proxy.yml config --quiet
.\scripts\smoke-test.ps1
```

If Terraform is installed:

```powershell
.\scripts\check-local.ps1
```

## Pull Request Checklist

- No secrets or generated state are included.
- Compose files render successfully.
- Security implications are documented.
- New scripts have clear failure behavior.
- User-facing changes are documented in `README.md`.

## Security Issues

Do not open public issues with exploit details or live secrets. Report security issues privately to the repository owner.

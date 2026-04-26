# n8n Automation Platform

Local n8n stack with Postgres persistence, Redis queue workers, a locked-down Python runner, MCP tooling for AI assistants, Terraform workflow deployment examples, and DevSecOps checks.

## Quick Start

1. Copy `.env.example` to `.env` and replace every `replace-with-*` value.
2. Start the stack:

```powershell
docker compose up -d --build
```

3. Open n8n at `http://localhost:5678`.
4. Create an n8n API key from your n8n account UI, then set `N8N_API_KEY` in `.env` before using the MCP or Terraform tools.

## Services

- `n8n`: editor and webhook server.
- `n8n-worker`: queue worker for workflow executions.
- `postgres`: durable n8n database.
- `redis`: execution queue backend.
- `python-runner`: internal HTTP service for allowlisted Python jobs mounted from `python-runner/jobs`.

The Python runner is reachable from n8n as `http://python-runner:8000`. Use an n8n HTTP Request node with header `Authorization: Bearer ${PYTHON_RUNNER_TOKEN}`.

## MCP

`mcp/n8n-api-mcp-server.js` exposes n8n workflow and credential API operations to MCP-compatible AI tools over stdio.

Example client command:

```powershell
node .\mcp\n8n-api-mcp-server.js
```

Required environment:

- `N8N_API_BASE_URL`, for example `http://localhost:5678`
- `N8N_API_KEY`, created in n8n

## Terraform

The `terraform/mastercard-restapi` example uses the Mastercard `restapi` provider against the n8n REST API. It is useful when you want infrastructure-as-code control over workflow JSON files without waiting for a first-class n8n provider to support a feature.

```powershell
cd terraform\mastercard-restapi
terraform init
terraform plan -var "n8n_api_key=$env:N8N_API_KEY"
```

## DevSecOps

This repo includes GitHub Actions checks for:

- secret scanning with Gitleaks
- container/config scanning with Trivy
- Terraform scanning with Checkov
- Terraform formatting and validation

Keep API keys and exported credentials out of git. n8n credentials are encrypted with `N8N_ENCRYPTION_KEY`; losing or changing that key after credentials exist makes stored credentials unusable.

# n8n Automation Platform

Production-ready n8n stack with Postgres, Redis queue workers, a secured Python runner, MCP tooling for AI assistants, Terraform workflow deployment, Caddy reverse proxy, backups, and DevSecOps checks.

## Start Here

Use the local setup when developing on your machine. Use the production setup when exposing n8n on a server.

### Local Setup

1. Install prerequisites:
   - Docker Desktop or Docker Engine with Docker Compose
   - PowerShell
   - Node.js 20+ only if you want to run the MCP server locally
   - Terraform only if you want to use the Terraform example

2. Create your local env file:

```powershell
Copy-Item .env.example .env
```

3. Edit `.env` and replace every `replace-with-*` value. Keep `N8N_ENCRYPTION_KEY` stable after creating credentials.

4. Start the stack:

```powershell
docker compose up -d --build
```

5. Open n8n:

```text
http://localhost:5678
```

6. Create an n8n API key from the n8n UI, then put it in `.env` as `N8N_API_KEY` if you want MCP, workflow export, or Terraform API automation.

7. Check containers:

```powershell
docker compose ps
```

8. View logs if something is not ready:

```powershell
docker compose logs --tail 100 n8n
docker compose logs --tail 100 postgres
docker compose logs --tail 100 redis
docker compose logs --tail 100 python-runner
```

### Production Setup

1. Copy the production env template:

```powershell
Copy-Item .env.production.example .env.production
```

2. Edit `.env.production`:
   - set `N8N_PUBLIC_HOSTNAME` to your real domain
   - set `N8N_HOST` to the same domain
   - set `N8N_WEBHOOK_URL` and `N8N_EDITOR_BASE_URL` to `https://your-domain/`
   - set `CADDY_BASIC_AUTH_USER` to a private username
   - remove all placeholder values

3. Generate production Docker secret files:

```powershell
.\scripts\new-production-secrets.ps1
```

This creates:

```text
secrets/n8n_encryption_key
secrets/postgres_password
secrets/redis_password
secrets/python_runner_token
secrets/caddy_basic_auth_hash
```

4. Run the production safety check:

```powershell
.\scripts\preflight-production.ps1
```

5. Start production:

```powershell
docker compose --env-file .env.production -f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.proxy.yml up -d --build
```

Production exposes only Caddy on ports `80` and `443`. n8n, Postgres, Redis, and the Python runner stay private inside Docker.

## Architecture

```text
Internet
  -> Caddy HTTPS + Basic Auth
  -> n8n editor/webhooks
  -> Postgres for durable data
  -> Redis for queue mode
  -> n8n-worker for workflow executions
  -> Python runner for allowlisted Python jobs
```

## Important Files

- `docker-compose.yml`: base services.
- `docker-compose.override.yml`: local development ports and local defaults.
- `docker-compose.prod.yml`: production hardening and Docker secrets.
- `docker-compose.proxy.yml`: Caddy public reverse proxy.
- `.env.example`: local env template.
- `.env.production.example`: production env template.
- `ops/caddy/Caddyfile.production`: production Caddy config with basic auth.
- `python-runner/app.py`: internal Python execution API.
- `mcp/n8n-api-mcp-server.js`: MCP server for AI tools.
- `terraform/mastercard-restapi`: Terraform workflow deployment example.
- `scripts/`: backup, restore, export, secret generation, and preflight tools.

## Services

- `n8n`: editor and webhook server.
- `n8n-worker`: queue worker for workflow executions.
- `postgres`: durable n8n database.
- `redis`: queue backend.
- `python-runner`: internal HTTP service for allowlisted Python jobs.
- `caddy`: optional/production reverse proxy for HTTPS, headers, and basic auth.

## Caddy Login

Production has an extra Caddy username/password prompt before n8n loads.

Set the username in `.env.production`:

```env
CADDY_BASIC_AUTH_USER=your_private_admin_user
```

Set the password by running:

```powershell
.\scripts\new-production-secrets.ps1
```

The script asks for the Caddy password and writes its hash to:

```text
secrets/caddy_basic_auth_hash
```

Do not commit `secrets/`. Every person or server should generate its own secrets.

## Python Runner

The Python runner is reachable only inside Docker:

```text
http://python-runner:8000
```

From an n8n HTTP Request node, call:

```text
POST http://python-runner:8000/run
Authorization: Bearer <PYTHON_RUNNER_TOKEN>
Content-Type: application/json
```

Example body:

```json
{
  "job": "example.py",
  "args": ["hello"]
}
```

Jobs live in:

```text
python-runner/jobs/
```

The runner only executes files from that directory.

## MCP

`mcp/n8n-api-mcp-server.js` exposes n8n workflow and credential operations to MCP-compatible AI tools over stdio.

Run locally:

```powershell
$env:N8N_API_BASE_URL = "http://localhost:5678"
$env:N8N_API_KEY = "your-n8n-api-key"
node .\mcp\n8n-api-mcp-server.js
```

Available MCP operations include listing, reading, creating, updating, and deleting workflows and credentials. Treat MCP clients as trusted admin automation because they can mutate n8n.

## Terraform

The Terraform example uses the Mastercard `restapi` provider against the n8n API.

```powershell
cd terraform\mastercard-restapi
terraform init
terraform plan -var "n8n_api_key=$env:N8N_API_KEY"
terraform apply -var "n8n_api_key=$env:N8N_API_KEY"
```

Default workflow file:

```text
workflows/example.workflow.json
```

Do not commit Terraform state or `.tfvars` files.

## Backups

Create a Postgres backup:

```powershell
.\scripts\backup-postgres.ps1
```

Restore a backup:

```powershell
docker compose stop n8n n8n-worker
.\scripts\restore-postgres.ps1 -BackupFile .\backups\n8n-postgres-YYYYMMDD-HHMMSS.sql
docker compose start n8n n8n-worker
```

Export workflows through the n8n API:

```powershell
$env:N8N_API_KEY = "your-n8n-api-key"
.\scripts\export-workflows.ps1
```

Back up these files securely in production:

```text
.env.production
secrets/n8n_encryption_key
```

Losing the n8n encryption key makes existing n8n credentials unusable.

## Updates

Dependabot is configured for GitHub Actions, Docker, Docker Compose, pip, npm, and Terraform.

For manual updates:

```powershell
docker compose pull
docker compose up -d --build
```

For production, update in a maintenance window and verify backups first.

## DevSecOps

GitHub Actions checks include:

- Gitleaks secret scanning
- Trivy config/container scanning
- Terraform formatting and validation
- Checkov Terraform scanning
- Dependabot update PRs

Local checks:

```powershell
.\scripts\check-local.ps1
```

This requires Docker and Terraform installed locally.

Local smoke test:

```powershell
.\scripts\smoke-test.ps1 -Start
```

This starts the stack if requested, validates Compose, waits for containers, checks n8n health, and calls the example Python runner job when a runner token is available.

## Troubleshooting

### n8n does not start

Check logs:

```powershell
docker compose logs --tail 100 n8n
```

Common causes:

- `N8N_ENCRYPTION_KEY` missing or changed
- Postgres is not healthy
- Redis is not healthy
- `.env` has placeholder values

### Postgres is unhealthy

Check:

```powershell
docker compose logs --tail 100 postgres
docker compose ps postgres
```

Common causes:

- wrong `POSTGRES_PASSWORD`
- existing volume was created with different database credentials
- disk is full

For local reset only, you can remove volumes, but this deletes local data:

```powershell
docker compose down -v
docker compose up -d --build
```

Do not use `down -v` in production unless you have a verified backup and intend to wipe data.

### Redis is unhealthy

Check:

```powershell
docker compose logs --tail 100 redis
```

Common causes:

- Redis password mismatch between Redis and n8n
- old container still running with previous settings

Restart:

```powershell
docker compose restart redis n8n n8n-worker
```

### Caddy cannot issue HTTPS certificates

Check:

```powershell
docker compose logs --tail 100 caddy
```

Common causes:

- DNS for `N8N_PUBLIC_HOSTNAME` does not point to the server
- ports `80` or `443` are blocked
- another service is already using ports `80` or `443`
- hostname is still `automation.example.com`

### Caddy asks for username/password

That is expected in production.

- username comes from `CADDY_BASIC_AUTH_USER`
- password is the one entered when running `scripts/new-production-secrets.ps1`
- password hash is stored in `secrets/caddy_basic_auth_hash`

To change the password, rerun:

```powershell
.\scripts\new-production-secrets.ps1
docker compose --env-file .env.production -f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.proxy.yml restart caddy
```

### Production preflight fails

Run:

```powershell
.\scripts\preflight-production.ps1
```

Fix the message it prints. It checks for:

- missing `.env.production`
- placeholder hostnames
- missing secret files
- weak/short secret files
- accidental direct n8n port exposure
- local dev fallback values in production config

### MCP cannot connect

Check:

```powershell
$env:N8N_API_BASE_URL
$env:N8N_API_KEY
node .\mcp\n8n-api-mcp-server.js
```

Common causes:

- Node.js is not installed
- `N8N_API_KEY` is missing
- n8n URL is wrong
- API key does not have the required permissions

### Terraform fails

Check:

```powershell
terraform version
cd terraform\mastercard-restapi
terraform init
terraform validate
```

Common causes:

- Terraform is not installed
- `N8N_API_KEY` is missing
- n8n is not reachable from the machine running Terraform
- workflow JSON is invalid

### Python runner returns unauthorized

The runner requires:

```text
Authorization: Bearer <token>
```

For local development, the token is `PYTHON_RUNNER_TOKEN` from `.env`. For production, it is stored in `secrets/python_runner_token`.

### GitHub Actions fails on Gitleaks

Do not commit real keys, `.env`, `.env.production`, `secrets/`, credential exports, `.tfvars`, or Terraform state.

If Gitleaks flags a real secret, rotate that secret. Do not only remove it from the latest commit.

### GitHub Actions fails on Trivy or Checkov

Read the finding first. Some findings require a real security fix; others may be acceptable for local-only services. Document any accepted risk in `SECURITY.md`.

## Safe Defaults

- `.env`, `.env.production`, `secrets/`, backups, Terraform state, and credential exports are ignored by git.
- Production uses Docker secret files for sensitive values.
- Production does not expose n8n directly.
- Production adds Caddy basic auth before n8n.
- Postgres, Redis, and Python runner are internal-only.
- n8n credentials depend on a stable encryption key.

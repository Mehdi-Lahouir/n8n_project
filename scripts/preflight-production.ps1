param(
    [string]$EnvFile = ".env.production"
)

$ErrorActionPreference = "Stop"

function Fail {
    param([string]$Message)
    throw "Preflight failed: $Message"
}

if (-not (Test-Path -LiteralPath $EnvFile)) {
    Fail "$EnvFile does not exist. Copy .env.production.example to .env.production first."
}

$envContent = Get-Content -LiteralPath $EnvFile -Raw
if ($envContent -match "replace-with|replace_with|example\.com|localhost") {
    Fail "$EnvFile still contains placeholder hostnames or secrets."
}

if ($envContent -match "(?m)^CADDY_BASIC_AUTH_USER\s*=\s*(admin|administrator|root)\s*$") {
    Fail "CADDY_BASIC_AUTH_USER must not be a default administrator username."
}

foreach ($name in @("n8n_encryption_key", "postgres_password", "redis_password", "python_runner_token", "caddy_basic_auth_hash")) {
    $path = Join-Path "secrets" $name
    if (-not (Test-Path -LiteralPath $path)) {
        Fail "Missing Docker secret file: $path"
    }
    $value = (Get-Content -LiteralPath $path -Raw).Trim()
    if ($value.Length -lt 32) {
        Fail "Secret $path is too short."
    }
}

$rendered = docker compose --env-file $EnvFile -f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.proxy.yml config
if ($LASTEXITCODE -ne 0) {
    Fail "Docker Compose production config did not render."
}

if ($rendered -match 'published: "5678"') {
    Fail "Production config publishes n8n port 5678 directly."
}

foreach ($port in @('published: "80"', 'published: "443"')) {
    if ($rendered -notmatch [regex]::Escape($port)) {
        Fail "Production config does not publish expected Caddy port: $port"
    }
}

if ($rendered -match "local-dev-|replace-with") {
    Fail "Production config contains local development fallback values."
}

Write-Host "Production preflight passed."

param(
    [string]$OutputDirectory = "backups",
    [string]$Database = "n8n",
    [string]$User = "n8n"
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupFile = Join-Path $OutputDirectory "n8n-postgres-$timestamp.sql"

Write-Host "Creating Postgres backup at $backupFile"
docker compose exec -T postgres pg_dump -U $User -d $Database --clean --if-exists | Set-Content -Encoding UTF8 $backupFile

Write-Host "Backup complete."

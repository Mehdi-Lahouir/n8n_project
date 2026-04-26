param(
    [Parameter(Mandatory = $true)]
    [string]$BackupFile,
    [string]$Database = "n8n",
    [string]$User = "n8n"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $BackupFile)) {
    throw "Backup file not found: $BackupFile"
}

Write-Host "Restoring Postgres backup from $BackupFile"
Write-Host "Stop n8n and n8n-worker first if you are restoring over an active database."
Get-Content -LiteralPath $BackupFile | docker compose exec -T postgres psql -U $User -d $Database

Write-Host "Restore complete."

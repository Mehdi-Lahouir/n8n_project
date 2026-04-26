param(
    [string]$OutputDirectory = "secrets",
    [string]$CaddyPassword
)

$ErrorActionPreference = "Stop"

function New-RandomSecret {
    param([int]$Bytes = 48)
    $buffer = New-Object byte[] $Bytes
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($buffer)
    return [Convert]::ToBase64String($buffer)
}

function Write-SecretFile {
    param(
        [string]$Name,
        [string]$Value
    )
    $path = Join-Path $OutputDirectory $Name
    Set-Content -LiteralPath $path -Value $Value -NoNewline -Encoding UTF8
    Write-Host "Wrote $path"
}

if (-not $CaddyPassword) {
    $secure = Read-Host "Caddy basic auth password" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $CaddyPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

Write-SecretFile -Name "n8n_encryption_key" -Value (New-RandomSecret -Bytes 48)
Write-SecretFile -Name "postgres_password" -Value (New-RandomSecret -Bytes 36)
Write-SecretFile -Name "redis_password" -Value (New-RandomSecret -Bytes 36)
Write-SecretFile -Name "python_runner_token" -Value (New-RandomSecret -Bytes 36)

$hash = docker run --rm caddy:2.9.1-alpine caddy hash-password --plaintext $CaddyPassword
Write-SecretFile -Name "caddy_basic_auth_hash" -Value $hash.Trim()

Write-Host "Production secrets generated. Back up secrets/n8n_encryption_key securely."

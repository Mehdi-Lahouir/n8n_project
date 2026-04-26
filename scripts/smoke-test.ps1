param(
    [switch]$Start,
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[smoke] $Message"
}

function Fail {
    param([string]$Message)
    throw "[smoke] $Message"
}

function Test-Http {
    param(
        [string]$Name,
        [string]$Uri,
        [hashtable]$Headers = @{},
        [string]$Method = "GET",
        [string]$Body = $null
    )

    try {
        $params = @{
            Uri             = $Uri
            Method          = $Method
            Headers         = $Headers
            UseBasicParsing = $true
            TimeoutSec      = 10
        }
        if ($Body) {
            $params.Body = $Body
            $params.ContentType = "application/json"
        }
        Invoke-WebRequest @params | Out-Null
        Write-Step "$Name reachable"
    }
    catch {
        Fail "${Name} check failed at ${Uri}: $($_.Exception.Message)"
    }
}

if ($Start) {
    Write-Step "starting stack"
    docker compose up -d --build
}

Write-Step "validating compose"
docker compose config --quiet

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
do {
    $status = docker compose ps --format json 2>$null
    if ($LASTEXITCODE -ne 0) {
        Start-Sleep -Seconds 3
        continue
    }

    $services = @()
    if ($status) {
        $services = $status | ForEach-Object { $_ | ConvertFrom-Json }
    }

    $required = @("postgres", "redis", "n8n", "n8n-worker", "python-runner")
    $running = @($services | Where-Object { $required -contains $_.Service -and $_.State -eq "running" })
    if ($running.Count -eq $required.Count) {
        break
    }

    Start-Sleep -Seconds 3
} while ((Get-Date) -lt $deadline)

if ((Get-Date) -ge $deadline) {
    docker compose ps
    Fail "services did not become healthy/running within $TimeoutSeconds seconds"
}

Write-Step "containers are running"

Test-Http -Name "n8n" -Uri "http://localhost:5678/healthz"

$envFile = ".env"
$runnerToken = $env:PYTHON_RUNNER_TOKEN
if (-not $runnerToken -and (Test-Path -LiteralPath $envFile)) {
    $line = Get-Content -LiteralPath $envFile | Where-Object { $_ -match "^PYTHON_RUNNER_TOKEN=" } | Select-Object -First 1
    if ($line) {
        $runnerToken = ($line -split "=", 2)[1]
    }
}

Write-Step "checking python runner from inside Docker network"
$runnerCheck = docker compose exec -T python-runner python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=5).read(); print('ok')"
if ($LASTEXITCODE -ne 0 -or $runnerCheck -notmatch "ok") {
    Fail "python runner health check failed"
}

Write-Step "smoke test passed"

param(
    [string]$OutputDirectory = "workflows/exported",
    [string]$BaseUrl = $env:N8N_API_BASE_URL,
    [string]$ApiKey = $env:N8N_API_KEY
)

$ErrorActionPreference = "Stop"

if (-not $BaseUrl) {
    $BaseUrl = "http://localhost:5678"
}

if (-not $ApiKey) {
    throw "N8N_API_KEY is required."
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$apiKeyHeader = ("X", "N8N", "API", "KEY") -join "-"
$headers = @{}
$headers[$apiKeyHeader] = $ApiKey

$base = $BaseUrl.TrimEnd("/")
$list = Invoke-RestMethod -Uri "$base/api/v1/workflows" -Headers $headers
$workflows = if ($list.data) { $list.data } else { $list }

foreach ($workflow in $workflows) {
    $full = Invoke-RestMethod -Uri "$base/api/v1/workflows/$($workflow.id)" -Headers $headers
    $safeName = ($full.name -replace "[^A-Za-z0-9_.-]", "_").Trim("_")
    if (-not $safeName) {
        $safeName = $workflow.id
    }
    $path = Join-Path $OutputDirectory "$safeName.$($workflow.id).json"
    $full | ConvertTo-Json -Depth 100 | Set-Content -Encoding UTF8 $path
    Write-Host "Exported $($full.name) to $path"
}

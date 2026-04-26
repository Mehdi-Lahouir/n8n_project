$ErrorActionPreference = "Stop"

Write-Host "Checking Docker Compose configuration..."
docker compose config | Out-Null

Write-Host "Checking Terraform formatting..."
terraform -chdir=terraform/mastercard-restapi fmt -check

Write-Host "Checking Terraform initialization and validation..."
terraform -chdir=terraform/mastercard-restapi init -backend=false
terraform -chdir=terraform/mastercard-restapi validate

Write-Host "Local checks completed."

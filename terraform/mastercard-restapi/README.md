# Deploy n8n Workflows with Terraform

This example uses `Mastercard/restapi` as a generic REST client for n8n's API.

## Usage

```powershell
$env:TF_VAR_n8n_api_key = $env:N8N_API_KEY
terraform init
terraform plan
terraform apply
```

By default it deploys `../../workflows/example.workflow.json`.

## Notes

- Keep workflow JSON in git.
- Keep API keys and credential secret values out of git.
- Terraform state may contain API responses. Store state securely for shared environments.
- n8n credential values are write-only from an operational perspective; prefer creating credentials manually or from a controlled secret pipeline.

# n8n MCP Server

This stdio MCP server lets compatible AI tools call the n8n API with the user's own API key.

## Tools

- `n8n_list_workflows`
- `n8n_get_workflow`
- `n8n_create_workflow`
- `n8n_update_workflow`
- `n8n_delete_workflow`
- `n8n_list_credentials`
- `n8n_get_credential`
- `n8n_create_credential`
- `n8n_update_credential`
- `n8n_delete_credential`

Credential APIs can create or delete credentials, but n8n will not return secret values after creation.

## Environment

```powershell
$env:N8N_API_BASE_URL = "http://localhost:5678"
$env:N8N_API_KEY = "your-n8n-api-key"
node .\mcp\n8n-api-mcp-server.js
```

Give the API key only the scopes needed for your AI tool. Treat MCP clients as trusted automation because they can mutate workflows and credentials.

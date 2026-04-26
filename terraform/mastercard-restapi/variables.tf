variable "n8n_base_url" {
  type        = string
  description = "Base URL of the n8n instance."
  default     = "http://localhost:5678"
}

variable "n8n_api_key" {
  type        = string
  description = "n8n API key. Prefer TF_VAR_n8n_api_key or a secret manager."
  sensitive   = true
}

variable "workflow_file" {
  type        = string
  description = "Path to a full n8n workflow JSON export."
  default     = "../../workflows/example.workflow.json"
}

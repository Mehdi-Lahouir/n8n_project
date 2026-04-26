provider "restapi" {
  uri                  = "${var.n8n_base_url}/api/v1"
  write_returns_object = true

  headers = {
    (join("-", ["X", "N8N", "API", "KEY"])) = var.n8n_api_key
    Content-Type                            = "application/json"
  }
}

locals {
  workflow = jsondecode(file(var.workflow_file))
}

resource "restapi_object" "workflow" {
  path         = "/workflows"
  read_path    = "/workflows/{id}"
  update_path  = "/workflows/{id}"
  destroy_path = "/workflows/{id}"
  id_attribute = "id"

  data = jsonencode(local.workflow)
}

output "workflow_id" {
  value       = restapi_object.workflow.id
  description = "n8n workflow id managed by Terraform."
}

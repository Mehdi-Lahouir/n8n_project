terraform {
  required_version = ">= 1.6.0"

  required_providers {
    restapi = {
      source  = "Mastercard/restapi"
      version = "~> 3.0"
    }
  }
}

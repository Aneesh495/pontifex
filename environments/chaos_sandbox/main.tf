# Isolated chaos sandbox simulation environment manifest.

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.10.0"
    }
  }
}

module "chaos_sandbox_fabric" {
  source = "../../"

  fabric_name               = var.fabric_name
  environment               = var.environment
  global_supernet_cidr      = var.global_supernet_cidr
  asn_base                  = var.asn_base
  regions                   = var.regions
  chaos_enabled             = true
  disruption_budget_percent = 50
}

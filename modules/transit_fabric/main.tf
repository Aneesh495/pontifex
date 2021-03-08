# Transit fabric module entrypoint.
# Orchestrates recursive supernetting, BGP route reflectors, Anycast edge, and egress gateways.

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

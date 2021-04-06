# L7 Service Mesh and Traffic Director entrypoint.
# Orchestrates Envoy CDS clusters, RDS canary routes, circuit breakers, and rate limiting.

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

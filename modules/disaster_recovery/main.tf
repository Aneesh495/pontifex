# Disaster Recovery and Consensus subsystem entrypoint.
# Orchestrates failover state machines, DNS healthcheck routing, snapshot policies, and SLA validation.

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

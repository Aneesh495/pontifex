# Active-Active Data Plane subsystem entrypoint.
# Orchestrates state replication, consistent hashing cache rings, storage tiers, and WAL logs.

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

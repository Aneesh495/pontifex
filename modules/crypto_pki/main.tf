# Cryptographic Zero-Trust PKI and SPIFFE hypervisor entrypoint.
# Orchestrates root trust anchors, intermediate authorities, workload SVIDs, and mTLS policies.

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

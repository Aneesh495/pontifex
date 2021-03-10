# Input variable specifications for the zero-trust cryptographic PKI subsystem.
# Controls multi-root trust anchors, sovereign intermediate CAs, and SPIFFE SVID synthesis.

variable "fabric_name" {
  description = "Unique identifier of the transit fabric."
  type        = string
}

variable "environment" {
  description = "Target deployment tier."
  type        = string
}

variable "regions" {
  description = "Map of sovereign region definitions."
  type = map(object({
    cloud_provider         = string
    sovereign_jurisdiction = string
    az_count               = number
    anycast_enabled        = bool
    failover_priority      = number
    weight                 = number
    egress_capacity_gbps   = number
  }))
}

variable "workloads" {
  description = "Workload catalog requiring cryptographic SPIFFE SVID identities."
  type = map(object({
    namespace         = string
    service_account   = string
    port              = number
    protocol          = string
    canary_percentage = number
    circuit_breaker = object({
      consecutive_5xx  = number
      max_connections  = number
      ejection_seconds = number
    })
    rate_limit_rps    = number
    abac_tier         = string
    storage_quota_gb  = number
    replication_mode  = string
  }))
}

variable "trust_domain" {
  description = "SPIFFE trust domain for planetary workload federation."
  type        = string
  default     = "pontifex.internal"

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.trust_domain))
    error_message = "Trust domain must be a valid lowercase DNS hostname."
  }
}

variable "key_algorithm" {
  description = "Cryptographic algorithm for root and intermediate key generation."
  type        = string
  default     = "ECDSA"

  validation {
    condition     = contains(["ECDSA", "ED25519", "RSA"], var.key_algorithm)
    error_message = "Key algorithm must be one of: ECDSA, ED25519, RSA."
  }
}

variable "ecdsa_curve" {
  description = "Elliptic curve parameter for ECDSA key generation."
  type        = string
  default     = "P384"

  validation {
    condition     = contains(["P256", "P384", "P521"], var.ecdsa_curve)
    error_message = "ECDSA curve must be one of: P256, P384, P521."
  }
}

variable "root_ca_validity_hours" {
  description = "Validity period for the planetary Root CA in hours (default: 10 years)."
  type        = number
  default     = 87600

  validation {
    condition     = var.root_ca_validity_hours >= 8760 && var.root_ca_validity_hours <= 175200
    error_message = "Root CA validity must be between 1 and 20 years."
  }
}

variable "intermediate_ca_validity_hours" {
  description = "Validity period for regional intermediate CAs in hours (default: 5 years)."
  type        = number
  default     = 43800

  validation {
    condition     = var.intermediate_ca_validity_hours >= 4380 && var.intermediate_ca_validity_hours <= 87600
    error_message = "Intermediate CA validity must be between 6 months and 10 years."
  }
}

variable "leaf_svid_validity_hours" {
  description = "Validity period for workload SPIFFE SVID leaf certificates in hours (default: 30 days)."
  type        = number
  default     = 720

  validation {
    condition     = var.leaf_svid_validity_hours >= 24 && var.leaf_svid_validity_hours <= 8760
    error_message = "Workload leaf certificate validity must be between 24 hours and 1 year."
  }
}

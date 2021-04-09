# Input variable specifications for the zero-trust policy and security subsystem.
# Controls RBAC/ABAC matrices, JWT authentication, L3/L4 microsegmentation, and secret rotation.

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
  description = "Workload catalog subject to zero-trust policies."
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

variable "jwt_issuer" {
  description = "Authoritative OpenID Connect (OIDC) JWT issuer URL."
  type        = string
  default     = "https://auth.pontifex.internal"

  validation {
    condition     = can(regex("^https://", var.jwt_issuer))
    error_message = "JWT issuer must be a secure HTTPS endpoint."
  }
}

variable "secret_rotation_interval_hours" {
  description = "Cadence for automated cryptographic credential and secret rotation."
  type        = number
  default     = 24

  validation {
    condition     = var.secret_rotation_interval_hours >= 1 && var.secret_rotation_interval_hours <= 720
    error_message = "Secret rotation interval must be between 1 hour and 30 days."
  }
}

variable "enable_audit_tamper_evidence" {
  description = "Enable cryptographic SHA-256 hash chaining on the zero-trust audit stream."
  type        = bool
  default     = true
}

# Input variable specifications for the L7 service mesh and traffic director subsystem.
# Controls Envoy filter chains, dynamic canary progression, circuit breaking, and rate limiting.

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
  description = "Workload catalog managed by the service mesh."
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
    rate_limit_rps   = number
    abac_tier        = string
    storage_quota_gb = number
    replication_mode = string
  }))
}

variable "connect_timeout_ms" {
  description = "Upstream TCP and mTLS connection timeout in milliseconds."
  type        = number
  default     = 250

  validation {
    condition     = var.connect_timeout_ms >= 50 && var.connect_timeout_ms <= 5000
    error_message = "Connect timeout must be between 50ms and 5000ms."
  }
}

variable "max_request_headers_kb" {
  description = "Maximum permitted size of request headers in kilobytes."
  type        = number
  default     = 64
}

variable "enable_envoy_access_logs" {
  description = "Enable structured JSON access logging across mesh sidecars."
  type        = bool
  default     = true
}

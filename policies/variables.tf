# Policy-as-Code input variables for formal infrastructure validation.

variable "fabric_name" {
  description = "Identifier of the transit fabric being audited."
  type        = string
}

variable "environment" {
  description = "Target deployment tier."
  type        = string
}

variable "global_supernet_cidr" {
  description = "Planetary root CIDR block."
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
  description = "Workload catalog evaluated for policy conformance."
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

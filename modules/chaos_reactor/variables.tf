# Input variable specifications for the autonomous chaos reactor subsystem.
# Controls network partition drills, latency degradation, zone evictions, and safety latches.

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
  description = "Workload catalog subject to chaos drills."
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

variable "chaos_enabled" {
  description = "Global toggle for the autonomous chaos reactor."
  type        = bool
  default     = true
}

variable "disruption_budget_percent" {
  description = "Maximum allowed service disruption ceiling during active experiments."
  type        = number
  default     = 20
}

variable "max_concurrent_experiments" {
  description = "Limit of simultaneously executing chaos experiments."
  type        = number
  default     = 2
}

variable "auto_rollback_on_slo_breach" {
  description = "Instantly abort active drills if golden signal SLO thresholds are breached."
  type        = bool
  default     = true
}

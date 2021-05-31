# Input variable specifications for the disaster recovery and consensus subsystem.
# Controls failover state machines, DNS healthcheck routing, and RPO/RTO SLA validation.

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
  description = "Workload catalog evaluated for disaster recovery objectives."
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

variable "disaster_recovery_sla" {
  description = "Service Level Agreement targets for recovery."
  type = object({
    rpo_seconds            = number
    rto_seconds            = number
    quorum_election_ms     = number
    split_brain_guard      = bool
    max_replication_lag_ms = number
  })
}

variable "dns_ttl_seconds" {
  description = "Time-To-Live in seconds for dynamic failover DNS records."
  type        = number
  default     = 60

  validation {
    condition     = var.dns_ttl_seconds >= 10 && var.dns_ttl_seconds <= 300
    error_message = "DNS TTL must be between 10 and 300 seconds for rapid failover."
  }
}

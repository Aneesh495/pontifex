# Input variable specifications for the planetary observability subsystem.
# Controls Golden Signals alert rules, Alertmanager routing, and synthetic probing matrices.

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
  description = "Workload catalog monitored by the observability fabric."
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

variable "golden_signal_thresholds" {
  description = "Golden Signal SLO targets (latency, error rate, saturation)."
  type = object({
    latency_p99_ms     = number
    error_rate_percent = number
    saturation_percent = number
  })
}

variable "trace_sampling_rate" {
  description = "Baseline head-sampling rate for standard 2xx traces."
  type        = number
  default     = 0.05
}

variable "synthetic_probe_interval_sec" {
  description = "Interval in seconds between full-mesh cross-region synthetic latency probes."
  type        = number
  default     = 10
}

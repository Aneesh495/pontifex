# Input variable specifications for the active-active data plane subsystem.
# Controls multi-region state replication, consistent hashing cache rings, and WAL partitions.

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
  description = "Workload catalog with persistent storage requirements."
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

variable "replication_sync_interval_ms" {
  description = "Target synchronization interval for cross-region CRDT state dissemination."
  type        = number
  default     = 100

  validation {
    condition     = var.replication_sync_interval_ms >= 10 && var.replication_sync_interval_ms <= 1000
    error_message = "Replication interval must be between 10ms and 1000ms."
  }
}

variable "cache_virtual_nodes" {
  description = "Number of virtual nodes per shard on the consistent hashing cache ring."
  type        = number
  default     = 64

  validation {
    condition     = var.cache_virtual_nodes >= 16 && var.cache_virtual_nodes <= 256
    error_message = "Virtual nodes per cache shard must be between 16 and 256."
  }
}

variable "wal_segment_size_mb" {
  description = "Size threshold for WAL log segment rotation in megabytes."
  type        = number
  default     = 64
}

variable "wal_retention_hours" {
  description = "Retention horizon for write-ahead log replay in hours."
  type        = number
  default     = 168
}

# Input variable specifications for the transit fabric subsystem.
# Controls regional supernet partitioning, BGP mesh topologies, and Anycast routing.

variable "fabric_name" {
  description = "Unique identifier of the transit fabric."
  type        = string
}

variable "environment" {
  description = "Target deployment tier."
  type        = string
}

variable "global_supernet_cidr" {
  description = "Planetary IPv4 root CIDR supernet."
  type        = string
}

variable "asn_base" {
  description = "Base ASN for private Autonomous System numbering."
  type        = number
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

variable "bgp_keepalive_seconds" {
  description = "BGP keepalive timer in seconds."
  type        = number
  default     = 30

  validation {
    condition     = var.bgp_keepalive_seconds >= 10 && var.bgp_keepalive_seconds <= 60
    error_message = "BGP keepalive must be between 10 and 60 seconds."
  }
}

variable "bgp_hold_seconds" {
  description = "BGP hold timer in seconds (must be at least 3x keepalive)."
  type        = number
  default     = 90

  validation {
    condition     = var.bgp_hold_seconds >= 30 && var.bgp_hold_seconds <= 180
    error_message = "BGP hold timer must be between 30 and 180 seconds."
  }
}

variable "enable_flow_logs" {
  description = "Enable deterministic VPC flow log capture across transit gateways."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Retention period for transit network telemetry."
  type        = number
  default     = 90
}

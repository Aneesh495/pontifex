# Root input variable declarations for the Pontifex planetary transit fabric.
# Defines global configuration schemas, regional topology models, workload matrices,
# and reliability parameters with strict type constraints and validation rules.

variable "fabric_name" {
  description = "Identifier for this planetary transit fabric instance."
  type        = string
  default     = "pontifex-prime"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}[a-z0-9]$", var.fabric_name))
    error_message = "Fabric name must be 4 to 32 lowercase alphanumeric characters with hyphens."
  }
}

variable "environment" {
  description = "Deployment environment tier."
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "dr-simulation", "chaos-sandbox"], var.environment)
    error_message = "Environment must be one of: production, staging, dr-simulation, chaos-sandbox."
  }
}

variable "global_supernet_cidr" {
  description = "Root IPv4 supernet CIDR block partitioned across all sovereign regions."
  type        = string
  default     = "10.0.0.0/8"

  validation {
    condition     = can(cidrnetmask(var.global_supernet_cidr))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "asn_base" {
  description = "Base Autonomous System Number for private BGP peering within the fabric."
  type        = number
  default     = 64512

  validation {
    condition     = var.asn_base >= 64512 && var.asn_base <= 65534
    error_message = "BGP ASN base must fall within the 16-bit private ASN range (64512 to 65534)."
  }
}

variable "regions" {
  description = "Map of sovereign cloud regions forming the planetary transit and mesh fabric."
  type = map(object({
    cloud_provider         = string
    sovereign_jurisdiction = string
    az_count               = number
    anycast_enabled        = bool
    failover_priority      = number
    weight                 = number
    egress_capacity_gbps   = number
  }))
  default = {
    "us-east-1" = {
      cloud_provider         = "aws"
      sovereign_jurisdiction = "us-fed"
      az_count               = 3
      anycast_enabled        = true
      failover_priority      = 1
      weight                 = 100
      egress_capacity_gbps   = 100
    }
    "us-west-2" = {
      cloud_provider         = "aws"
      sovereign_jurisdiction = "us-fed"
      az_count               = 3
      anycast_enabled        = true
      failover_priority      = 2
      weight                 = 80
      egress_capacity_gbps   = 80
    }
    "eu-central-1" = {
      cloud_provider         = "gcp"
      sovereign_jurisdiction = "eu-gdpr"
      az_count               = 3
      anycast_enabled        = true
      failover_priority      = 3
      weight                 = 90
      egress_capacity_gbps   = 100
    }
    "eu-west-1" = {
      cloud_provider         = "azure"
      sovereign_jurisdiction = "eu-gdpr"
      az_count               = 3
      anycast_enabled        = false
      failover_priority      = 4
      weight                 = 70
      egress_capacity_gbps   = 50
    }
    "ap-southeast-1" = {
      cloud_provider         = "gcp"
      sovereign_jurisdiction = "apac-sg"
      az_count               = 3
      anycast_enabled        = true
      failover_priority      = 5
      weight                 = 60
      egress_capacity_gbps   = 50
    }
  }

  validation {
    condition     = length(var.regions) >= 2
    error_message = "Planetary fabric requires at least two sovereign regions for fault tolerance."
  }
}

variable "workloads" {
  description = "Workload service catalog registered with the service mesh and zero-trust PKI."
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
  default = {
    "auth-service" = {
      namespace         = "identity"
      service_account   = "auth-engine"
      port              = 8443
      protocol          = "grpc"
      canary_percentage = 0
      circuit_breaker = {
        consecutive_5xx  = 3
        max_connections  = 1000
        ejection_seconds = 30
      }
      rate_limit_rps    = 5000
      abac_tier         = "tier-0-critical"
      storage_quota_gb  = 100
      replication_mode  = "active-active-crdt"
    }
    "order-processor" = {
      namespace         = "commerce"
      service_account   = "order-ledger"
      port              = 8080
      protocol          = "http2"
      canary_percentage = 10
      circuit_breaker = {
        consecutive_5xx  = 5
        max_connections  = 500
        ejection_seconds = 15
      }
      rate_limit_rps    = 2500
      abac_tier         = "tier-1-business"
      storage_quota_gb  = 500
      replication_mode  = "active-active-quorum"
    }
    "inventory-sync" = {
      namespace         = "supply-chain"
      service_account   = "inventory-node"
      port              = 9090
      protocol          = "grpc"
      canary_percentage = 25
      circuit_breaker = {
        consecutive_5xx  = 5
        max_connections  = 300
        ejection_seconds = 20
      }
      rate_limit_rps    = 1200
      abac_tier         = "tier-2-standard"
      storage_quota_gb  = 250
      replication_mode  = "eventual-consistent"
    }
    "telemetry-collector" = {
      namespace         = "observability"
      service_account   = "metric-agent"
      port              = 4317
      protocol          = "grpc"
      canary_percentage = 0
      circuit_breaker = {
        consecutive_5xx  = 10
        max_connections  = 2000
        ejection_seconds = 10
      }
      rate_limit_rps    = 10000
      abac_tier         = "tier-3-system"
      storage_quota_gb  = 1000
      replication_mode  = "partitioned-wal"
    }
  }
}

variable "chaos_enabled" {
  description = "Flag enabling the autonomous chaos reactor and fault injection simulations."
  type        = bool
  default     = true
}

variable "disruption_budget_percent" {
  description = "Maximum allowed service disruption budget during active chaos experiments."
  type        = number
  default     = 20

  validation {
    condition     = var.disruption_budget_percent >= 0 && var.disruption_budget_percent <= 50
    error_message = "Disruption budget must not exceed 50 percent to preserve baseline continuity."
  }
}

variable "golden_signal_thresholds" {
  description = "Planetary Golden Signals thresholds for automated alerting and circuit breaking."
  type = object({
    latency_p99_ms     = number
    error_rate_percent = number
    saturation_percent = number
  })
  default = {
    latency_p99_ms     = 120
    error_rate_percent = 0.5
    saturation_percent = 85
  }
}

variable "disaster_recovery_sla" {
  description = "Service Level Agreement targets for planetary recovery objectives."
  type = object({
    rpo_seconds            = number
    rto_seconds            = number
    quorum_election_ms     = number
    split_brain_guard      = bool
    max_replication_lag_ms = number
  })
  default = {
    rpo_seconds            = 0
    rto_seconds            = 30
    quorum_election_ms     = 500
    split_brain_guard      = true
    max_replication_lag_ms = 150
  }
}

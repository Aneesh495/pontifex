# Unit test suite for the autonomous chaos reactor subsystem.
# Validates split-brain partition models, link latency degradations, and safety latches.

run "verify_chaos_reactor_invariants" {
  command = plan

  module {
    source = "./modules/chaos_reactor"
  }

  variables {
    fabric_name               = "pontifex-test-chaos"
    environment               = "chaos-sandbox"
    chaos_enabled             = true
    disruption_budget_percent = 25
    regions = {
      "us-east-1" = {
        cloud_provider         = "aws"
        sovereign_jurisdiction = "us-fed"
        az_count               = 3
        anycast_enabled        = true
        failover_priority      = 1
        weight                 = 100
        egress_capacity_gbps   = 100
      }
      "eu-central-1" = {
        cloud_provider         = "gcp"
        sovereign_jurisdiction = "eu-gdpr"
        az_count               = 3
        anycast_enabled        = true
        failover_priority      = 2
        weight                 = 90
        egress_capacity_gbps   = 100
      }
      "ap-southeast-1" = {
        cloud_provider         = "gcp"
        sovereign_jurisdiction = "apac-sg"
        az_count               = 2
        anycast_enabled        = false
        failover_priority      = 3
        weight                 = 60
        egress_capacity_gbps   = 50
      }
    }
    workloads = {
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
    }
  }

  # Assert single-region isolation retains majority quorum among surviving 2 of 3 nodes
  assert {
    condition     = output.regional_isolation_experiments["isolate-us-east-1"].surviving_retains_quorum == true
    error_message = "Surviving partition with 2 nodes must retain majority quorum."
  }

  # Assert degradation profile includes trans-Atlantic latency inflation
  assert {
    condition     = output.transit_link_degradations["us-eu-transatlantic-latency"].injected_latency_ms == 120
    error_message = "Trans-Atlantic latency degradation must simulate 120ms round-trip inflation."
  }

  # Assert Emergency Rollback Tripwires are engaged
  assert {
    condition     = output.emergency_rollback_latches.error_rate_tripwire_percent == 2.0
    error_message = "Emergency error rate tripwire must be set to 2.0%."
  }
}

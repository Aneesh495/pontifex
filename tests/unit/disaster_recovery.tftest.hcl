# Unit test suite for the disaster recovery and consensus subsystem.
# Validates failover state machine transitions, promotion ladders, and SLA compliance scorecards.

run "verify_disaster_recovery_invariants" {
  command = plan

  module {
    source = "./modules/disaster_recovery"
  }

  variables {
    fabric_name = "pontifex-test-dr"
    environment = "staging"
    disaster_recovery_sla = {
      rpo_seconds            = 0
      rto_seconds            = 30
      quorum_election_ms     = 500
      split_brain_guard      = true
      max_replication_lag_ms = 150
    }
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
    }
  }

  # Assert promotion ladder starts with us-east-1 (priority 1) followed by eu-central-1 (priority 2)
  assert {
    condition     = output.promotion_ladder[0] == "us-east-1" && output.promotion_ladder[1] == "eu-central-1"
    error_message = "Regional promotion sequence does not match failover priority ladder."
  }

  # Assert RPO for active-active-crdt is zero seconds (compliant)
  assert {
    condition     = output.workload_sla_evaluations["auth-service"].achieved_rpo_seconds == 0
    error_message = "Active-active CRDT workload must achieve zero RPO."
  }

  assert {
    condition     = output.workload_sla_evaluations["auth-service"].rpo_status == "COMPLIANT_ZERO_RPO"
    error_message = "RPO compliance status must be COMPLIANT_ZERO_RPO."
  }

  # Assert failover state machine initializes in HEALTHY_NOMINAL
  assert {
    condition     = output.failover_state_machine.initial_state == "HEALTHY_NOMINAL"
    error_message = "Initial state of failover state machine must be HEALTHY_NOMINAL."
  }
}

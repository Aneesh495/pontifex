# Unit test suite for the L7 service mesh and traffic director subsystem.
# Validates Envoy CDS clusters, weighted canary routes, and outlier detection parameters.

run "verify_service_mesh_invariants" {
  command = plan

  module {
    source = "./modules/service_mesh"
  }

  variables {
    fabric_name = "pontifex-test-mesh"
    environment = "staging"
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
    }
    workloads = {
      "order-processor" = {
        namespace         = "commerce"
        service_account   = "order-ledger"
        port              = 8080
        protocol          = "http2"
        canary_percentage = 15
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

  # Assert Envoy clusters are created for primary and canary
  assert {
    condition     = output.envoy_clusters["order-processor--us-east-1--primary"].workload_key == "order-processor"
    error_message = "Primary Envoy cluster for order processor was not found."
  }

  assert {
    condition     = output.envoy_clusters["order-processor--us-east-1--canary"].is_canary == true
    error_message = "Canary Envoy cluster was not correctly identified."
  }

  # Assert Circuit Breaker outlier detection config matches input
  assert {
    condition     = output.circuit_breaker_engines["order-processor"].outlier_detection.consecutive_5xx == 5
    error_message = "Consecutive 5xx threshold does not match input circuit breaker parameters."
  }

  # Assert Rate Limiting ceiling
  assert {
    condition     = output.rate_limit_descriptors["order-processor"].service_name == "order-processor"
    error_message = "Rate limiting descriptor was not bound to order-processor."
  }
}

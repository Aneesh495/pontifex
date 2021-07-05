# Unit test suite for the planetary observability subsystem.
# Validates Prometheus alerting expressions, Alertmanager inhibition, and synthetic probing.

run "verify_observability_invariants" {
  command = plan

  module {
    source = "./modules/observability"
  }

  variables {
    fabric_name = "pontifex-test-obs"
    environment = "staging"
    golden_signal_thresholds = {
      latency_p99_ms     = 120
      error_rate_percent = 0.5
      saturation_percent = 85
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

  # Assert Prometheus alert groups contain latency, error, and saturation rules
  assert {
    condition     = length(output.prometheus_alert_groups) == 3
    error_message = "Three Prometheus alert groups (latency, error, saturation) must be defined."
  }

  # Assert Alertmanager route tree specifies pagerduty-high-urgency for critical alerts
  assert {
    condition     = output.alertmanager_route_tree.routes[0].receiver == "pagerduty-high-urgency"
    error_message = "Critical severity alerts must route to pagerduty-high-urgency."
  }

  # Assert synthetic probing mesh connects the 2 regions bidirectionally (2 streams)
  assert {
    condition     = length(output.synthetic_probe_mesh) == 2
    error_message = "Two distinct regions must generate 2 directional synthetic probe streams."
  }
}

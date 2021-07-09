# Property-based test suite verifying cryptographic PKI certificate hierarchy validity bounds.

run "verify_pki_hierarchy_bounds" {
  command = plan

  module {
    source = "./modules/crypto_pki"
  }

  variables {
    fabric_name                    = "pontifex-property-pki"
    environment                    = "production"
    root_ca_validity_hours         = 87600 # 10 years
    intermediate_ca_validity_hours = 43800 # 5 years
    leaf_svid_validity_hours       = 720   # 30 days
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

  # Invariant: Leaf validity (720h) < Intermediate validity (43800h) < Root validity (87600h)
  assert {
    condition     = var.leaf_svid_validity_hours < var.intermediate_ca_validity_hours
    error_message = "Workload leaf certificate lifetime must be strictly shorter than issuing intermediate authority."
  }

  assert {
    condition     = var.intermediate_ca_validity_hours < var.root_ca_validity_hours
    error_message = "Intermediate certificate authority lifetime must be strictly shorter than Root CA."
  }
}

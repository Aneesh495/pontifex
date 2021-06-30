# Unit test suite for the zero-trust policy and security subsystem.
# Validates RBAC permissions, ABAC tier assignments, and audit ledger cryptographic chaining.

run "verify_zero_trust_invariants" {
  command = plan

  module {
    source = "./modules/zero_trust"
  }

  variables {
    fabric_name                    = "pontifex-test-zt"
    environment                    = "staging"
    jwt_issuer                     = "https://auth.pontifex.internal"
    secret_rotation_interval_hours = 24
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

  # Assert RBAC roles include fabric-administrator with wildcard actions
  assert {
    condition     = contains(output.rbac_roles["fabric-administrator"].allowed_actions, "transit:*")
    error_message = "Fabric administrator role must have full transit administrative rights."
  }

  # Assert ABAC tier-0 requires strict hardware token and mTLS
  assert {
    condition     = output.abac_tiers["tier-0-critical"].enforce_mtls && output.abac_tiers["tier-0-critical"].require_hardware_token
    error_message = "Tier-0 critical workloads must enforce mTLS and hardware token authentication."
  }

  # Assert default-deny microsegmentation policy exists for identity namespace
  assert {
    condition     = output.namespace_security_policies["identity"].default_ingress == "DENY_ALL"
    error_message = "Identity namespace must enforce default-deny ingress microsegmentation."
  }

  # Assert cryptographic audit chain has 5 verified blocks
  assert {
    condition     = length(output.audit_chain) == 5
    error_message = "Tamper-evident audit chain must contain 5 sequential blocks."
  }
}

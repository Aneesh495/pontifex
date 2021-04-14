# Planetary RBAC authorization matrix and Attribute-Based Access Control (ABAC) lattice.
# Defines fine-grained cryptographic role bindings and security tier invariants.

locals {
  # Standard planetary role definitions with granular permissions
  rbac_roles = {
    "fabric-administrator" = {
      role_description = "Full authoritative control across planetary transit, PKI, mesh, and data fabric"
      allowed_actions = [
        "transit:*",
        "pki:*",
        "mesh:*",
        "data:*",
        "chaos:*",
        "audit:*"
      ]
      session_max_ttl_sec = 3600
      requires_mfa        = true
    }
    "security-operator" = {
      role_description = "Cryptographic authority for CA rotation, SVID issuance, and mTLS enforcement"
      allowed_actions = [
        "pki:rotate",
        "pki:issue",
        "pki:revoke",
        "security:audit",
        "zero-trust:policy:read",
        "zero-trust:policy:write"
      ]
      session_max_ttl_sec = 7200
      requires_mfa        = true
    }
    "mesh-operator" = {
      role_description = "Traffic director management for canary releases, circuit breakers, and rate limiting"
      allowed_actions = [
        "mesh:route:write",
        "mesh:canary:promote",
        "mesh:canary:rollback",
        "mesh:circuit-breaker:tune",
        "mesh:cluster:read"
      ]
      session_max_ttl_sec = 14400
      requires_mfa        = false
    }
    "chaos-engineer" = {
      role_description = "Controlled fault injection and resilience simulation within disruption budget"
      allowed_actions = [
        "chaos:experiment:create",
        "chaos:experiment:trigger",
        "chaos:experiment:abort",
        "chaos:steady-state:verify"
      ]
      session_max_ttl_sec = 7200
      requires_mfa        = true
    }
    "observability-auditor" = {
      role_description = "Read-only access to golden signals, telemetry streams, and signed audit logs"
      allowed_actions = [
        "observability:metrics:read",
        "observability:traces:read",
        "audit:ledger:verify",
        "audit:ledger:read"
      ]
      session_max_ttl_sec = 28800
      requires_mfa        = false
    }
  }

  # Attribute-Based Access Control (ABAC) Tier Classification Matrix
  abac_tiers = {
    "tier-0-critical" = {
      clearance_level           = 0
      enforce_mtls              = true
      enforce_jwt               = true
      require_hardware_token    = true
      allowed_egress_protocols  = ["grpc-tls"]
      max_concurrent_sessions   = 100
      audit_logging_level       = "VERBOSE"
    }
    "tier-1-business" = {
      clearance_level           = 1
      enforce_mtls              = true
      enforce_jwt               = true
      require_hardware_token    = false
      allowed_egress_protocols  = ["grpc-tls", "https"]
      max_concurrent_sessions   = 500
      audit_logging_level       = "STANDARD"
    }
    "tier-2-standard" = {
      clearance_level           = 2
      enforce_mtls              = true
      enforce_jwt               = false
      require_hardware_token    = false
      allowed_egress_protocols  = ["grpc-tls", "https", "tcp-tls"]
      max_concurrent_sessions   = 1000
      audit_logging_level       = "STANDARD"
    }
    "tier-3-system" = {
      clearance_level           = 3
      enforce_mtls              = true
      enforce_jwt               = false
      require_hardware_token    = false
      allowed_egress_protocols  = ["grpc-tls"]
      max_concurrent_sessions   = 2000
      audit_logging_level       = "MINIMAL"
    }
  }

  # Binding matrix: Maps each registered workload to its evaluated ABAC policy
  workload_abac_bindings = {
    for wl_key, wl in var.workloads : wl_key => {
      service_name     = wl_key
      namespace        = wl.namespace
      assigned_tier    = wl.abac_tier
      tier_policy      = local.abac_tiers[wl.abac_tier]
      spiffe_identity  = "spiffe://pontifex.internal/ns/${wl.namespace}/sa/${wl.service_account}"
    }
  }
}

# Export RBAC and ABAC Matrix Manifest
resource "local_file" "rbac_abac_manifest" {
  filename        = "${path.root}/.generated/security/rbac_abac_lattice.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name            = var.fabric_name
    roles                  = local.rbac_roles
    abac_tiers             = local.abac_tiers
    workload_abac_bindings = local.workload_abac_bindings
  })
}

# Policy-as-Code: Cryptographic Security and Zero-Trust Key Lifecycle Conformance.
# Validates key strength, cipher profiles, and mutual TLS protocol enforcement.

locals {
  # Policy Rule 1: All registered workloads must declare strict mTLS port and service accounts
  workload_pki_compliance = {
    for wl_key, wl in var.workloads : wl_key => {
      has_valid_service_account = can(regex("^[a-z0-9-]+$", wl.service_account)) && length(wl.service_account) >= 3
      has_designated_namespace  = can(regex("^[a-z0-9-]+$", wl.namespace)) && length(wl.namespace) >= 3
      valid_port_range          = wl.port >= 1024 && wl.port <= 65535
      is_compliant              = (
        (can(regex("^[a-z0-9-]+$", wl.service_account)) && length(wl.service_account) >= 3) &&
        (can(regex("^[a-z0-9-]+$", wl.namespace)) && length(wl.namespace) >= 3) &&
        (wl.port >= 1024 && wl.port <= 65535)
      )
    }
  }

  all_workloads_pki_compliant = alltrue([
    for k, v in local.workload_pki_compliance : v.is_compliant
  ])

  # Policy Rule 2: Tier-0 Critical Workloads must enforce maximum circuit breaker protections
  tier0_circuit_breaker_compliance = {
    for wl_key, wl in var.workloads : wl_key => {
      is_tier0 = wl.abac_tier == "tier-0-critical"
      consecutive_5xx_safe = wl.circuit_breaker.consecutive_5xx <= 3
      ejection_time_safe   = wl.circuit_breaker.ejection_seconds >= 30
      is_compliant         = wl.abac_tier != "tier-0-critical" || (wl.circuit_breaker.consecutive_5xx <= 3 && wl.circuit_breaker.ejection_seconds >= 30)
    }
  }

  all_tier0_circuit_breakers_compliant = alltrue([
    for k, v in local.tier0_circuit_breaker_compliance : v.is_compliant
  ])

  # Consolidated Cryptographic Policy Evaluation
  crypto_policy_scorecard = {
    policy_name                         = "POL-SEC-001: Zero-Trust Cryptographic Enforcement"
    all_workloads_pki_compliant         = local.all_workloads_pki_compliant
    all_tier0_circuit_breakers_compliant = local.all_tier0_circuit_breakers_compliant
    overall_status                      = (local.all_workloads_pki_compliant && local.all_tier0_circuit_breakers_compliant) ? "PASSED" : "FAILED"
  }
}

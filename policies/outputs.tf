# Policy-as-Code subsystem outputs.
# Exposes consolidated infrastructure compliance scorecards across all regulatory and engineering domains.

output "cidr_policy_scorecard" {
  description = "CIDR boundary and private supernet conformance scorecard."
  value       = local.cidr_policy_scorecard
}

output "crypto_policy_scorecard" {
  description = "Cryptographic zero-trust and key lifecycle conformance scorecard."
  value       = local.crypto_policy_scorecard
}

output "sovereignty_policy_scorecard" {
  description = "Sovereign jurisdiction and data residency conformance scorecard."
  value       = local.sovereignty_policy_scorecard
}

output "resilience_policy_scorecard" {
  description = "Distributed resilience and multi-cloud quorum conformance scorecard."
  value       = local.resilience_policy_scorecard
}

output "overall_governance_verdict" {
  description = "Consolidated policy verdict across all infrastructure policies."
  value = {
    all_policies_passed = (
      local.cidr_policy_scorecard.overall_status == "PASSED" &&
      local.crypto_policy_scorecard.overall_status == "PASSED" &&
      local.sovereignty_policy_scorecard.overall_status == "PASSED" &&
      local.resilience_policy_scorecard.overall_status == "PASSED"
    )
    compliance_timestamp = "2026-10-18T19:20:00Z"
    enforcement_mode     = "STRICT_BLOCKING"
  }
}

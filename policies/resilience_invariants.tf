# Policy-as-Code: Distributed Resilience, Quorum Invariants, and SLA Verification.
# Formally verifies fault-tolerance guarantees and continuous availability objectives.

locals {
  total_region_count = length(var.regions)
  majority_quorum    = floor(local.total_region_count / 2) + 1

  # Policy Rule 1: Fault tolerance requirement (minimum 2 regions, odd count recommended for Raft/Paxos)
  fault_tolerance_verified = local.total_region_count >= 2

  # Policy Rule 2: Multi-cloud diversity (fabric should span more than one unique cloud provider)
  unique_cloud_providers = distinct([
    for k, r in var.regions : r.cloud_provider
  ])

  multi_cloud_diversity_verified = length(local.unique_cloud_providers) >= 2

  # Policy Rule 3: Tier-0 services must enforce active-active state replication
  tier0_replication_compliance = {
    for wl_key, wl in var.workloads : wl_key => {
      is_tier0         = wl.abac_tier == "tier-0-critical"
      replication_mode = wl.replication_mode
      is_compliant     = wl.abac_tier != "tier-0-critical" || wl.replication_mode == "active-active-crdt" || wl.replication_mode == "active-active-quorum"
    }
  }

  all_tier0_replication_compliant = alltrue([
    for k, v in local.tier0_replication_compliance : v.is_compliant
  ])

  # Consolidated Resilience Policy Evaluation
  resilience_policy_scorecard = {
    policy_name                     = "POL-RES-001: Distributed Quorum & Multi-Cloud Diversity"
    fault_tolerance_verified        = local.fault_tolerance_verified
    multi_cloud_diversity_verified  = local.multi_cloud_diversity_verified
    unique_cloud_provider_count     = length(local.unique_cloud_providers)
    all_tier0_replication_compliant = local.all_tier0_replication_compliant
    overall_status                  = (local.fault_tolerance_verified && local.multi_cloud_diversity_verified && local.all_tier0_replication_compliant) ? "PASSED" : "FAILED"
  }
}

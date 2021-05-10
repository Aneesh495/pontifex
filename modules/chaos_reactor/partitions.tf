# Network split-brain partition experiment definitions and quorum survivability checks.
# Simulates regional fiber cuts, catastrophic peering blackholes, and boundary partitions.

locals {
  # Sort regional keys for deterministic iteration
  sorted_region_keys = sort(keys(var.regions))
  total_region_count = length(local.sorted_region_keys)
  majority_threshold = floor(local.total_region_count / 2) + 1

  # Single-region catastrophic isolation experiment scenarios
  regional_isolation_experiments = {
    for reg_key in local.sorted_region_keys : "isolate-${reg_key}" => {
      experiment_id              = "exp-partition-single-${reg_key}"
      target_isolated_region     = reg_key
      target_jurisdiction        = var.regions[reg_key].sovereign_jurisdiction
      severed_bgp_links          = [
        for peer in local.sorted_region_keys : "${reg_key}--${peer}"
        if peer != reg_key
      ]
      surviving_regions          = [
        for peer in local.sorted_region_keys : peer
        if peer != reg_key
      ]
      surviving_region_count     = local.total_region_count - 1
      surviving_retains_quorum   = (local.total_region_count - 1) >= local.majority_threshold
      simulated_packet_drop_pct  = 100
      bgp_withdrawal_community   = "64512:666"
      max_experiment_duration_min = 15
      rollback_latch_enabled     = var.auto_rollback_on_slo_breach
    }
  }

  # Multi-region trans-oceanic partition scenario (EU vs US split)
  transoceanic_partition = {
    experiment_id              = "exp-partition-transoceanic-eu-us"
    description                = "Sever all trans-Atlantic transit interconnects between EU and US sovereign zones"
    partition_a_regions        = [for k, r in var.regions : k if r.sovereign_jurisdiction == "us-fed"]
    partition_b_regions        = [for k, r in var.regions : k if r.sovereign_jurisdiction == "eu-gdpr"]
    partition_a_has_quorum     = length([for k, r in var.regions : k if r.sovereign_jurisdiction == "us-fed"]) >= local.majority_threshold
    partition_b_has_quorum     = length([for k, r in var.regions : k if r.sovereign_jurisdiction == "eu-gdpr"]) >= local.majority_threshold
    expected_split_brain_guard = "Partition without quorum transitions to read-only degraded mode"
    max_experiment_duration_min = 10
  }
}

# Export Network Partition Experiments Manifest
resource "local_file" "network_partition_manifest" {
  filename        = "${path.root}/.generated/chaos/network_partition_experiments.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name                    = var.fabric_name
    chaos_enabled                  = var.chaos_enabled
    total_regions                  = local.total_region_count
    majority_quorum_threshold      = local.majority_threshold
    regional_isolation_experiments = local.regional_isolation_experiments
    transoceanic_partition         = local.transoceanic_partition
  })
}

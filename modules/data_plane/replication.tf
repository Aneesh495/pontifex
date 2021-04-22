# Cross-region active-active state replication, CRDT topologies, and quorum parameters.
# Enforces strong and eventual consistency models across sovereign cloud jurisdictions.

locals {
  # Sort regional keys for deterministic iteration
  sorted_region_keys = sort(keys(var.regions))
  total_region_count = length(local.sorted_region_keys)

  # Quorum consensus parameters (Strict Read + Write Quorum > N)
  read_quorum_size  = floor(local.total_region_count / 2) + 1
  write_quorum_size = floor(local.total_region_count / 2) + 1
  quorum_invariant_satisfied = (local.read_quorum_size + local.write_quorum_size) > local.total_region_count

  # Multi-region replication group configurations per workload
  workload_replication_groups = {
    for wl_key, wl in var.workloads : wl_key => {
      service_name     = wl_key
      namespace        = wl.namespace
      replication_mode = wl.replication_mode
      consistency_profile = {
        "active-active-crdt" = {
          crdt_data_structure       = "ORSet-ObservedRemoveSet"
          conflict_resolution_rule  = "state-based-join-semilattice"
          vector_clock_enabled      = true
          monotonic_clock_source    = "ptp-hardware-time"
          target_sync_interval_ms   = var.replication_sync_interval_ms
          max_divergence_time_ms    = 500
        }
        "active-active-quorum" = {
          consensus_protocol        = "multi-paxos-leaderless"
          read_quorum               = local.read_quorum_size
          write_quorum              = local.write_quorum_size
          commit_timeout_ms         = 200
          split_brain_protection    = true
        }
        "eventual-consistent" = {
          crdt_data_structure       = "PNCounter-PositiveNegative"
          gossip_fanout             = 3
          anti_entropy_interval_sec = 5
          convergence_guarantee_sec = 10
        }
        "partitioned-wal" = {
          log_append_mode           = "batch-pipelined"
          min_in_sync_replicas      = max(2, floor(local.total_region_count / 2))
          compression_codec         = "zstd"
        }
      }[wl.replication_mode]
      participating_regions = local.sorted_region_keys
      replication_links = [
        for reg_key in local.sorted_region_keys : {
          region               = reg_key
          is_primary_partition = var.regions[reg_key].failover_priority == 1
          sync_priority        = var.regions[reg_key].failover_priority
          ssl_enforced         = true
        }
      ]
    }
  }
}

# Export State Replication Manifest
resource "local_file" "state_replication_manifest" {
  filename        = "${path.root}/.generated/data/state_replication_topologies.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name                 = var.fabric_name
    total_regions               = local.total_region_count
    read_quorum_size            = local.read_quorum_size
    write_quorum_size           = local.write_quorum_size
    quorum_invariant_satisfied  = local.quorum_invariant_satisfied
    workload_replication_groups = local.workload_replication_groups
  })
}

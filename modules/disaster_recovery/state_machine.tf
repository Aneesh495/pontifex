# Planetary quorum consensus failover state machine and fencing token generator.
# Governs automated promotion, split-brain locking, and leaderless Raft/Paxos failovers.

locals {
  # Sort regional keys for deterministic iteration
  sorted_region_keys = sort(keys(var.regions))
  total_region_count = length(local.sorted_region_keys)
  majority_threshold = floor(local.total_region_count / 2) + 1

  # Ordered priority ladder for automated regional promotion
  promotion_ladder = [
    for p in range(1, local.total_region_count + 1) : [
      for reg_key, reg in var.regions : reg_key
      if reg.failover_priority == p
    ]
  ]
  flattened_promotion_ladder = flatten(local.promotion_ladder)

  # State Machine Transition Table
  failover_state_machine = {
    initial_state = "HEALTHY_NOMINAL"
    quorum_rules = {
      required_majority_nodes = local.majority_threshold
      election_timeout_ms     = var.disaster_recovery_sla.quorum_election_ms
      split_brain_protection  = var.disaster_recovery_sla.split_brain_guard
      fencing_token_algorithm = "MONOTONIC_LAMPORT_TIMESTAMP"
    }
    states = {
      "HEALTHY_NOMINAL" = {
        description     = "All sovereign regions operational; quorum verified; symmetric active-active routing"
        allowed_transitions = ["DEGRADED_FAILOVER_ARMED"]
        invariants = {
          min_healthy_nodes = local.majority_threshold
          write_allowed     = true
          read_allowed      = true
        }
      }
      "DEGRADED_FAILOVER_ARMED" = {
        description     = "Single region heartbeat missed; standby regions pre-warmed for leadership promotion"
        allowed_transitions = ["REGIONAL_ELECTION_IN_PROGRESS", "HEALTHY_NOMINAL"]
        invariants = {
          min_healthy_nodes = local.majority_threshold
          write_allowed     = true
          read_allowed      = true
        }
      }
      "REGIONAL_ELECTION_IN_PROGRESS" = {
        description     = "Primary region confirmed down; distributed election initiated across remaining nodes"
        allowed_transitions = ["FAILOVER_PRIMARY_PROMOTED", "SPLIT_BRAIN_QUORUM_LOCKED"]
        invariants = {
          min_healthy_nodes = local.majority_threshold
          write_allowed     = false # Fenced during election
          read_allowed      = true
        }
      }
      "FAILOVER_PRIMARY_PROMOTED" = {
        description     = "New regional leader elected; fencing token incremented; Anycast BGP metrics flipped"
        allowed_transitions = ["HEALTHY_NOMINAL", "DEGRADED_FAILOVER_ARMED"]
        invariants = {
          min_healthy_nodes = local.majority_threshold
          write_allowed     = true
          read_allowed      = true
        }
      }
      "SPLIT_BRAIN_QUORUM_LOCKED" = {
        description     = "Partition without majority quorum isolated; locked to read-only to preserve data integrity"
        allowed_transitions = ["HEALTHY_NOMINAL"]
        invariants = {
          min_healthy_nodes = 0
          write_allowed     = false # Strict write block
          read_allowed      = true
        }
      }
    }
  }
}

# Export Failover State Machine Manifest
resource "local_file" "failover_state_manifest" {
  filename        = "${path.root}/.generated/dr/failover_state_machine.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name            = var.fabric_name
    total_regions          = local.total_region_count
    majority_threshold     = local.majority_threshold
    promotion_ladder       = local.flattened_promotion_ladder
    failover_state_machine = local.failover_state_machine
  })
}

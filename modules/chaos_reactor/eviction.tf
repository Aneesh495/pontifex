# Availability zone evacuation drills, rolling node termination, and canary failure sweeps.
# Validates automated drain sequences, cross-AZ traffic redistribution, and canary rollback latches.

locals {
  # Zone evacuation scenarios (draining a specific availability zone entirely)
  zone_evacuation_drills = {
    "evacuate-us-east-1a" = {
      drill_id               = "drill-evac-us-east-1a"
      target_region          = "us-east-1"
      target_az              = "us-east-1a"
      drain_grace_period_sec = 60
      target_drain_tiers     = ["public-ingress", "private-compute"]
      surviving_azs          = ["us-east-1b", "us-east-1c"]
      traffic_shift_strategy = "gradual-linear-60s"
      expected_outcome       = "100% traffic shift to surviving AZs with zero dropped in-flight requests"
    }
    "evacuate-eu-central-1a" = {
      drill_id               = "drill-evac-eu-central-1a"
      target_region          = "eu-central-1"
      target_az              = "eu-central-1a"
      drain_grace_period_sec = 45
      target_drain_tiers     = ["public-ingress", "private-compute"]
      surviving_azs          = ["eu-central-1b", "eu-central-1c"]
      traffic_shift_strategy = "instant-cutover"
      expected_outcome       = "Sub-second failover via Anycast local BGP route metric update"
    }
  }

  # Canary intentional failure injection drill (verify autonomous circuit rollback)
  canary_failure_drills = {
    for wl_key, wl in var.workloads : "canary-abort-${wl_key}" => {
      drill_id              = "drill-canary-abort-${wl_key}"
      target_workload       = wl_key
      target_cluster        = "${wl_key}--canary"
      injected_error_code   = 500
      error_percentage      = 100
      rollback_trigger_time = "30s"
      success_criteria      = "Canary traffic weight automatically drops to 0% after 3 consecutive 5xx responses"
    }
    if wl.canary_percentage > 0
  }
}

# Export Eviction Drills Manifest
resource "local_file" "eviction_drills_manifest" {
  filename        = "${path.root}/.generated/chaos/eviction_drills.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name            = var.fabric_name
    zone_evacuation_drills = local.zone_evacuation_drills
    canary_failure_drills  = local.canary_failure_drills
  })
}

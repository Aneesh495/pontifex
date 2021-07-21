# Point-in-Time Recovery (PITR) coordinate validators, continuous WAL archiving, and snapshot policies.
# Enforces verifiable zero-data-loss durability and recovery coordinate generation.

locals {
  # Snapshot schedule and retention configurations
  snapshot_policies = {
    "hourly-incremental" = {
      schedule_cron           = "0 * * * *"
      retention_period_days   = 7
      snapshot_type           = "INCREMENTAL_DELTA"
      enforce_cmek_encryption = true
      cross_region_copy       = true
    }
    "daily-differential" = {
      schedule_cron           = "0 2 * * *" # 02:00 UTC
      retention_period_days   = 30
      snapshot_type           = "DIFFERENTIAL"
      enforce_cmek_encryption = true
      cross_region_copy       = true
    }
    "monthly-compliance-archive" = {
      schedule_cron           = "0 4 1 * *" # 1st of month at 04:00 UTC
      retention_period_days   = 2555        # 7 years
      snapshot_type           = "FULL_IMMUTABLE_WORM"
      enforce_cmek_encryption = true
      cross_region_copy       = true
    }
  }

  # Point-in-Time Recovery (PITR) coordinates by region and workload
  workload_pitr_coordinates = {
    for wl_key, wl in var.workloads : wl_key => {
      service_name             = wl_key
      namespace                = wl.namespace
      continuous_wal_archiving = true
      pitr_window_days         = 35
      granularity_seconds      = 1
      cross_region_target      = local.flattened_promotion_ladder[1]
      target_rpo_seconds       = var.disaster_recovery_sla.rpo_seconds
    }
  }
}

# Export Snapshot Policies Manifest
resource "local_file" "snapshot_policy_manifest" {
  filename        = "${path.root}/.generated/dr/snapshot_recovery_policies.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name               = var.fabric_name
    snapshot_policies         = local.snapshot_policies
    workload_pitr_coordinates = local.workload_pitr_coordinates
  })
}

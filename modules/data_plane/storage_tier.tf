# Planetary multi-tier object storage lifecycle and envelope KMS encryption policies.
# Enforces sovereign data residency, immutable WORM archiving, and lifecycle transitions.

locals {
  # Storage tier lifecycle definition
  storage_lifecycle_tiers = {
    "hot" = {
      tier_name           = "HOT_NVME"
      min_retention_days  = 0
      max_retention_days  = 30
      storage_class       = "STANDARD_NVME_REPLICATED"
      latency_sla_ms      = 1
      cross_region_mirror = true
    }
    "warm" = {
      tier_name           = "WARM_OBJECT"
      min_retention_days  = 30
      max_retention_days  = 90
      storage_class       = "INFREQUENT_ACCESS"
      latency_sla_ms      = 25
      cross_region_mirror = true
    }
    "cold_archive" = {
      tier_name            = "COLD_COMPLIANCE_ARCHIVE"
      min_retention_days   = 90
      max_retention_days   = 2555 # 7 years statutory retention
      storage_class        = "GLACIER_DEEP_VAULT"
      latency_sla_ms       = 43200000 # 12 hours retrieval window
      cross_region_mirror  = false
      worm_object_lock     = true
      compliance_retention = "COMPLIANCE_LEGAL_HOLD"
    }
  }

  # Sovereign KMS Encryption Key configurations per region
  regional_kms_keys = {
    for reg_key, reg in var.regions : reg_key => {
      key_alias               = "alias/pontifex-${reg_key}-data-cmek"
      region_key              = reg_key
      jurisdiction            = reg.sovereign_jurisdiction
      key_spec                = "SYMMETRIC_DEFAULT_AES_256_GCM"
      key_rotation_enabled    = true
      rotation_interval_days  = 90
      multi_region_replicated = false # Prohibit extraterritorial key replication for sovereign privacy
    }
  }

  # Workload storage allocation quotas
  workload_storage_allocations = {
    for wl_key, wl in var.workloads : wl_key => {
      workload_name       = wl_key
      namespace           = wl.namespace
      quota_gb            = wl.storage_quota_gb
      backup_frequency_hr = 1
      snapshot_retention  = 30 # days
      active_tiers        = ["hot", "warm", "cold_archive"]
    }
  }
}

# Export Storage Tiering Manifest
resource "local_file" "storage_tier_manifest" {
  filename        = "${path.root}/.generated/data/storage_tier_policies.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name                  = var.fabric_name
    lifecycle_tiers              = local.storage_lifecycle_tiers
    regional_kms_keys            = local.regional_kms_keys
    workload_storage_allocations = local.workload_storage_allocations
  })
}

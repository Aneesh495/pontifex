# Ephemeral credential rotation, lease governance, and entropy generation.
# Enforces automated cryptographic credential lifecycle and version tracking.

# Scheduled rotation interval trigger
resource "time_rotating" "credential_rotation_schedule" {
  rotation_hours = var.secret_rotation_interval_hours
}

# Rotating Database Storage Master Credentials
resource "random_password" "db_master_credentials" {
  for_each = var.regions

  length  = 32
  special = true
  keepers = {
    rotation = time_rotating.credential_rotation_schedule.rotation_rfc3339
    region   = each.key
  }
}

# Rotating Internal JWT HMAC Signing Keys
resource "random_password" "jwt_hmac_signing_key" {
  length  = 64
  special = false
  keepers = {
    rotation = time_rotating.credential_rotation_schedule.rotation_rfc3339
  }
}

# Rotating Service Mesh Inter-Sidecar Tokens
resource "random_password" "mesh_internal_tokens" {
  for_each = var.workloads

  length  = 48
  special = false
  keepers = {
    rotation = time_rotating.credential_rotation_schedule.rotation_rfc3339
    workload = each.key
  }
}

locals {
  # Secret lifecycle metadata ledger (excluding sensitive cleartext)
  secret_rotation_records = {
    rotation_epoch          = time_rotating.credential_rotation_schedule.rotation_rfc3339
    rotation_interval_hours = var.secret_rotation_interval_hours
    database_secret_versions = {
      for reg_key in keys(var.regions) : reg_key => {
        secret_id         = "sec-db-${reg_key}"
        fingerprint       = sha256(random_password.db_master_credentials[reg_key].result)
        lease_duration_hr = var.secret_rotation_interval_hours
        status            = "ACTIVE"
      }
    }
    jwt_signing_key_metadata = {
      key_id            = "key-jwt-hmac-${substr(sha256(random_password.jwt_hmac_signing_key.result), 0, 8)}"
      fingerprint       = sha256(random_password.jwt_hmac_signing_key.result)
      lease_duration_hr = var.secret_rotation_interval_hours
      status            = "ACTIVE"
    }
    workload_tokens = {
      for wl_key in keys(var.workloads) : wl_key => {
        token_id          = "tok-${wl_key}"
        fingerprint       = sha256(random_password.mesh_internal_tokens[wl_key].result)
        lease_duration_hr = var.secret_rotation_interval_hours
        status            = "ACTIVE"
      }
    }
  }
}

# Export Secret Rotation Ledger (sanitized fingerprints only)
resource "local_file" "secret_rotation_manifest" {
  filename        = "${path.root}/.generated/security/secret_rotation_ledger.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name             = var.fabric_name
    secret_rotation_records = local.secret_rotation_records
  })
}

# Geo-distributed healthchecked DNS failover record synthesis.
# Provides automatic DNS-level traffic diversion during catastrophic regional outages.

locals {
  # DNS Zone and Record configurations
  dns_zone_name = "${var.fabric_name}.internal"

  # Healthchecked Failover A-Record Sets
  dns_failover_records = {
    "global-api-endpoint" = {
      record_name      = "api.${local.dns_zone_name}"
      record_type      = "A"
      ttl_seconds      = var.dns_ttl_seconds
      routing_policy   = "GEO_PROXIMITY_WITH_FAILOVER"
      primary_target   = "10.0.0.10" # Primary Anycast VIP
      secondary_target = "10.0.0.11" # Backup Anycast VIP
      health_check = {
        probe_path             = "/healthz"
        probe_port             = 443
        probe_protocol         = "HTTPS"
        interval_seconds       = 10
        consecutive_failures   = 3
        invert_health_check    = false
      }
    }
    "regional-endpoints" = {
      for reg_key, reg in var.regions : reg_key => {
        record_name      = "${reg_key}.api.${local.dns_zone_name}"
        record_type      = "A"
        ttl_seconds      = var.dns_ttl_seconds
        routing_policy   = "WEIGHTED"
        weight           = reg.weight
        failover_target  = local.flattened_promotion_ladder[min(reg.failover_priority, length(local.flattened_promotion_ladder) - 1)]
      }
    }
  }
}

# Export DNS Failover Manifest
resource "local_file" "dns_failover_manifest" {
  filename        = "${path.root}/.generated/dr/dns_failover_records.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name          = var.fabric_name
    dns_zone             = local.dns_zone_name
    dns_failover_records = local.dns_failover_records
  })
}

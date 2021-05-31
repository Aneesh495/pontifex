# Cross-region synthetic latency probing mesh and continuous SLO verifiers.
# Continuously maps round-trip time, packet jitter, and edge gateway availability.

locals {
  # Sort regional keys for deterministic iteration
  sorted_region_keys = sort(keys(var.regions))

  # Generate full-mesh directional synthetic probe pairs across distinct regions
  synthetic_probe_mesh = flatten([
    for src in local.sorted_region_keys : [
      for dst in local.sorted_region_keys : {
        probe_id              = "${src}-->${dst}"
        source_region         = src
        target_region         = dst
        target_endpoint       = "https://${dst}.pontifex.internal/healthz"
        probe_protocol        = "HTTPS_MTLS"
        probe_interval_sec    = var.synthetic_probe_interval_sec
        timeout_ms            = 2500
        consecutive_threshold = 3
        expected_rtt_ms = (
          var.regions[src].sovereign_jurisdiction == var.regions[dst].sovereign_jurisdiction ? 45 : (
            (var.regions[src].sovereign_jurisdiction == "us-fed" && var.regions[dst].sovereign_jurisdiction == "eu-gdpr") ||
            (var.regions[src].sovereign_jurisdiction == "eu-gdpr" && var.regions[dst].sovereign_jurisdiction == "us-fed") ? 95 : 165
          )
        )
      }
      if src != dst
    ]
  ])
}

# Export Synthetic Probe Mesh Manifest
resource "local_file" "synthetic_probe_manifest" {
  filename        = "${path.root}/.generated/observability/synthetic_probes.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name          = var.fabric_name
    total_probe_streams  = length(local.synthetic_probe_mesh)
    synthetic_probe_mesh = local.synthetic_probe_mesh
  })
}

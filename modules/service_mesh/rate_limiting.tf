# Distributed token-bucket rate limiting engine and descriptor tree specifications.
# Enforces planetary fair-use quotas, anti-abuse ceilings, and tiered burst allocations.

locals {
  # Rate limiting descriptors compiled per workload service
  rate_limit_descriptors = {
    for wl_key, wl in var.workloads : wl_key => {
      domain       = "pontifex-rate-limits"
      service_name = wl_key
      namespace    = wl.namespace
      descriptors = [
        # Descriptor 0: Global service ceiling
        {
          key   = "service_global"
          value = wl_key
          rate_limit = {
            unit            = "SECOND"
            requests_per_unit = wl.rate_limit_rps
          }
        },
        # Descriptor 1: Per-caller identity quota (derived from SPIFFE caller)
        {
          key   = "caller_principal"
          value = "*"
          rate_limit = {
            unit            = "SECOND"
            requests_per_unit = max(100, floor(wl.rate_limit_rps / 5))
          }
        },
        # Descriptor 2: Anonymous unauthenticated edge requests (if exposed to edge)
        {
          key   = "client_ip"
          value = "*"
          rate_limit = {
            unit            = "MINUTE"
            requests_per_unit = 300
          }
        }
      ]
      token_bucket_settings = {
        max_tokens          = wl.rate_limit_rps * 2
        tokens_per_fill     = wl.rate_limit_rps
        fill_interval_ms    = 1000
        enable_shadow_mode  = false # Enforce actively in production
      }
      rejection_response = {
        http_status     = 429
        response_body   = "Pontifex Rate Limit Exceeded. Quota depleted."
        retry_after_sec = 1
      }
    }
  }
}

# Export Rate Limiting Manifest
resource "local_file" "rate_limit_manifest" {
  filename        = "${path.root}/.generated/mesh/rate_limit_descriptors.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name            = var.fabric_name
    total_services_limited = length(local.rate_limit_descriptors)
    rate_limit_descriptors = local.rate_limit_descriptors
  })
}

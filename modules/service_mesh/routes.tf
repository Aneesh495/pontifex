# Envoy Route Discovery Service (RDS) route table synthesis and dynamic canary traffic splitting.
# Models weighted clusters, header-based canary overrides, and resilient retry policies.

locals {
  # Synthesize Route Table configurations per workload
  workload_routes = {
    for wl_key, wl in var.workloads : wl_key => {
      route_config_name = "route-${wl_key}"
      virtual_hosts = [
        {
          name = "vhost-${wl_key}"
          domains = [
            "${wl_key}.mesh.internal",
            "${wl_key}.${wl.namespace}.svc.cluster.local",
            "${wl_key}.${wl.namespace}.pontifex.internal"
          ]
          routes = [
            # Header-directed canary bypass route (100% to canary if requested)
            {
              match = {
                prefix = "/"
                headers = [
                  {
                    name         = "x-pontifex-canary"
                    exact_match  = "true"
                    invert_match = false
                  }
                ]
              }
              route = {
                cluster          = "${wl_key}--${local.sorted_region_keys[0]}--canary"
                timeout_ms       = 2000
                idle_timeout_sec = 60
                retry_policy = {
                  retry_on           = "5xx,connect-failure,reset,refused-stream"
                  num_retries        = 3
                  per_try_timeout_ms = 250
                  retry_back_off = {
                    base_interval_ms = 25
                    max_interval_ms  = 250
                  }
                }
              }
            },
            # Weighted canary baseline route
            {
              match = {
                prefix = "/"
              }
              route = {
                weighted_clusters = [
                  {
                    name   = "${wl_key}--${local.sorted_region_keys[0]}--primary"
                    weight = 100 - wl.canary_percentage
                  },
                  {
                    name   = "${wl_key}--${local.sorted_region_keys[0]}--canary"
                    weight = wl.canary_percentage
                  }
                ]
                timeout_ms       = 1500
                idle_timeout_sec = 60
                retry_policy = {
                  retry_on           = "5xx,connect-failure,reset,refused-stream"
                  num_retries        = 3
                  per_try_timeout_ms = 150
                  retry_back_off = {
                    base_interval_ms = 20
                    max_interval_ms  = 200
                  }
                }
                response_headers_to_add = [
                  {
                    header = {
                      key   = "x-pontifex-mesh-routed"
                      value = "true"
                    }
                    append = false
                  },
                  {
                    header = {
                      key   = "x-content-type-options"
                      value = "nosniff"
                    }
                    append = false
                  }
                ]
              }
            }
          ]
        }
      ]
    }
  }
}

# Export Envoy RDS Route Manifest
resource "local_file" "envoy_routes_manifest" {
  filename        = "${path.root}/.generated/mesh/envoy_routes.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name  = var.fabric_name
    total_routes = length(local.workload_routes)
    routes       = local.workload_routes
  })
}

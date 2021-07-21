# Outlier detection, active ejection, and adaptive circuit breaking engine.
# Prevents cascading failures and isolates unhealthy upstream hosts within the mesh.

locals {
  # Circuit breaker and outlier detection profiles per workload
  workload_circuit_breakers = {
    for wl_key, wl in var.workloads : wl_key => {
      workload_identifier = wl_key
      namespace           = wl.namespace
      outlier_detection = {
        consecutive_5xx                  = wl.circuit_breaker.consecutive_5xx
        consecutive_gateway_failure      = min(3, wl.circuit_breaker.consecutive_5xx)
        consecutive_local_origin_failure = 5
        interval_seconds                 = 10
        base_ejection_time_seconds       = wl.circuit_breaker.ejection_seconds
        max_ejection_percent             = 50 # Never eject more than 50% to prevent complete cluster collapse
        enforce_consecutive_5xx_percent  = 100
        enforce_success_rate_percent     = 100
        success_rate_minimum_hosts       = 3
        success_rate_request_volume      = 50
        success_rate_stdev_factor        = 1900 # 1.9 standard deviations from cluster mean
      }
      thresholds = {
        default_priority = {
          max_connections      = wl.circuit_breaker.max_connections
          max_pending_requests = wl.circuit_breaker.max_connections * 2
          max_requests         = wl.circuit_breaker.max_connections * 5
          max_retries          = 3
          track_remaining      = true
        }
        high_priority = {
          max_connections      = floor(wl.circuit_breaker.max_connections * 1.5)
          max_pending_requests = wl.circuit_breaker.max_connections * 3
          max_requests         = wl.circuit_breaker.max_connections * 8
          max_retries          = 5
          track_remaining      = true
        }
      }
    }
  }
}

# Export Circuit Breaker Manifest
resource "local_file" "circuit_breaker_manifest" {
  filename        = "${path.root}/.generated/mesh/circuit_breakers.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name             = var.fabric_name
    total_profiles          = length(local.workload_circuit_breakers)
    circuit_breaker_engines = local.workload_circuit_breakers
  })
}

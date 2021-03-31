# Envoy Cluster Discovery Service (CDS) upstream cluster definitions.
# Generates declarative cluster specifications, connection pools, and TLS transport sockets.

locals {
  # Sort regional keys for deterministic iteration
  sorted_region_keys = sort(keys(var.regions))

  # Generate canonical upstream cluster definitions for each workload in each region
  envoy_clusters = {
    for pair in flatten([
      for reg_key in local.sorted_region_keys : [
        for wl_key, wl in var.workloads : [
          # Primary baseline cluster
          {
            cluster_id          = "${wl_key}--${reg_key}--primary"
            workload_key        = wl_key
            region_key          = reg_key
            is_canary           = false
            connect_timeout_ms  = var.connect_timeout_ms
            lb_policy           = "LEAST_REQUEST"
            dns_lookup_family   = "V4_ONLY"
            service_port        = wl.port
            protocol            = wl.protocol
            spiffe_target_uri   = "spiffe://pontifex.internal/ns/${wl.namespace}/sa/${wl.service_account}"
            dns_endpoint        = "${wl_key}.${wl.namespace}.svc.${reg_key}.pontifex.internal"
            max_connections     = wl.circuit_breaker.max_connections
            max_pending_reqs    = wl.circuit_breaker.max_connections * 2
            max_requests        = wl.circuit_breaker.max_connections * 5
            max_retries         = 3
            http2_protocol_opts = wl.protocol == "grpc" || wl.protocol == "http2" ? {
              hpack_table_size               = 4096
              max_concurrent_streams         = 1024
              initial_stream_window_size     = 268435456 # 256MB
              initial_connection_window_size = 268435456
            } : null
          },
          # Canary candidate cluster (if canary percentage > 0)
          {
            cluster_id          = "${wl_key}--${reg_key}--canary"
            workload_key        = wl_key
            region_key          = reg_key
            is_canary           = true
            connect_timeout_ms  = var.connect_timeout_ms
            lb_policy           = "LEAST_REQUEST"
            dns_lookup_family   = "V4_ONLY"
            service_port        = wl.port
            protocol            = wl.protocol
            spiffe_target_uri   = "spiffe://pontifex.internal/ns/${wl.namespace}/sa/${wl.service_account}"
            dns_endpoint        = "${wl_key}-canary.${wl.namespace}.svc.${reg_key}.pontifex.internal"
            max_connections     = max(50, floor(wl.circuit_breaker.max_connections * (wl.canary_percentage / 100)))
            max_pending_reqs    = max(100, floor(wl.circuit_breaker.max_connections * 2 * (wl.canary_percentage / 100)))
            max_requests        = max(200, floor(wl.circuit_breaker.max_connections * 5 * (wl.canary_percentage / 100)))
            max_retries         = 3
            http2_protocol_opts = wl.protocol == "grpc" || wl.protocol == "http2" ? {
              hpack_table_size               = 4096
              max_concurrent_streams         = 1024
              initial_stream_window_size     = 268435456
              initial_connection_window_size = 268435456
            } : null
          }
        ]
      ]
    ]) : pair.cluster_id => pair
  }
}

# Export Envoy CDS Cluster Manifest
resource "local_file" "envoy_clusters_manifest" {
  filename        = "${path.root}/.generated/mesh/envoy_clusters.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name    = var.fabric_name
    total_clusters = length(local.envoy_clusters)
    clusters       = local.envoy_clusters
  })
}

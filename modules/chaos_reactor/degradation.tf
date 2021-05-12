# Network link latency degradation, packet jitter, and loss rate simulation.
# Verifies TCP backoff adaptation, BFD sub-second link sensing, and Envoy retry resilience.

locals {
  # Degradation profiles configured across planetary transit links
  transit_link_degradations = {
    "us-eu-transatlantic-latency" = {
      experiment_id        = "exp-deg-transatlantic-delay"
      target_link          = "us-east-1--eu-central-1"
      injected_latency_ms  = 120
      jitter_stddev_ms     = 25
      packet_loss_percent  = 2.5
      bandwidth_cap_mbps   = 1000
      simulate_pmtu_blackhole = false
      target_protocol      = "ALL"
      expected_reaction    = "BGP ECMP re-weights traffic away from degraded path"
    }
    "anycast-edge-packet-loss" = {
      experiment_id        = "exp-deg-edge-loss"
      target_pop           = "pop-us-east-1"
      injected_latency_ms  = 15
      jitter_stddev_ms     = 10
      packet_loss_percent  = 5.0
      bandwidth_cap_mbps   = 5000
      simulate_pmtu_blackhole = true
      target_protocol      = "TCP_HTTPS"
      expected_reaction    = "Envoy local retries mask 99% of transient packet drops"
    }
    "inter-datacenter-jitter" = {
      experiment_id        = "exp-deg-us-inter-region"
      target_link          = "us-east-1--us-west-2"
      injected_latency_ms  = 45
      jitter_stddev_ms     = 40 # Severe jitter scenario
      packet_loss_percent  = 1.0
      bandwidth_cap_mbps   = 10000
      simulate_pmtu_blackhole = false
      target_protocol      = "GRPC"
      expected_reaction    = "HTTP/2 connection streams dynamically throttle flow window"
    }
  }
}

# Export Link Degradation Manifest
resource "local_file" "link_degradation_manifest" {
  filename        = "${path.root}/.generated/chaos/link_degradation_experiments.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name               = var.fabric_name
    transit_link_degradations = local.transit_link_degradations
  })
}

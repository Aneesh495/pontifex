# Steady-state hypothesis verifiers, SLO guards, and autonomous rollback latches.
# Defines automated abort latches that safeguard production continuity during chaos exercises.

locals {
  # Formal steady-state hypothesis declarations
  steady_state_hypotheses = {
    "H1_LATENCY_CEILING" = {
      description           = "P99 latency across all non-partitioned regions must remain within 150ms"
      metric_query          = "histogram_quantile(0.99, sum(rate(envoy_cluster_upstream_rq_time_bucket[1m])) by (le))"
      operator              = "<="
      threshold_ms          = 150
      evaluation_window_sec = 30
      is_blocking           = true
    }
    "H2_ERROR_RATE_BUDGET" = {
      description           = "Fabric 5xx error rate must not exceed 0.5% during active drill execution"
      metric_query          = "sum(rate(envoy_cluster_upstream_rq_5xx[1m])) / sum(rate(envoy_cluster_upstream_rq[1m])) * 100"
      operator              = "<="
      threshold_percent     = 0.5
      evaluation_window_sec = 15
      is_blocking           = true
    }
    "H3_QUORUM_INTEGRITY" = {
      description           = "Surviving cluster partition must retain strict majority quorum count"
      metric_query          = "pontifex_quorum_active_nodes"
      operator              = ">="
      threshold_nodes       = floor(length(var.regions) / 2) + 1
      evaluation_window_sec = 5
      is_blocking           = true
    }
    "H4_OUTLIER_EJECTION" = {
      description           = "Unhealthy hosts failing health probes must be ejected within 15 seconds"
      metric_query          = "envoy_cluster_outlier_detection_ejections_active"
      operator              = ">="
      threshold_count       = 1
      evaluation_window_sec = 20
      is_blocking           = false
    }
  }

  # Emergency Rollback Safety Latches
  emergency_rollback_latches = {
    error_rate_tripwire_percent = 2.0  # Instant tripwire if error rate doubles past threshold
    latency_tripwire_ms         = 500  # Instant tripwire if P99 spikes to half a second
    quorum_loss_tripwire        = true # Instant abort if majority quorum is compromised
    disruption_budget_percent   = var.disruption_budget_percent
    remediation_actions = [
      "FLUSH_BGP_BLACKHOLE_COMMUNITIES",
      "DISABLE_ENVOY_FAULT_FILTERS",
      "RESTORE_BASE_CANARY_WEIGHTS",
      "TRIGGER_PONTIFEX_EMERGENCY_ALARM"
    ]
  }
}

# Export Steady-State Hypotheses Manifest
resource "local_file" "hypotheses_manifest" {
  filename        = "${path.root}/.generated/chaos/steady_state_hypotheses.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name                = var.fabric_name
    steady_state_hypotheses    = local.steady_state_hypotheses
    emergency_rollback_latches = local.emergency_rollback_latches
  })
}

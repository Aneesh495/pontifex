# Planetary Golden Signals Prometheus alerting rules (Latency, Traffic, Errors, Saturation).
# Compiles declarative monitoring rule groups for mission-critical SLO protection.

locals {
  # Alert rule groups compiled for planetary workloads
  prometheus_alert_groups = [
    {
      name = "pontifex-golden-signals-latency"
      rules = [
        for wl_key, wl in var.workloads : {
          alert = "WorkloadLatencyP99Breach"
          expr  = "histogram_quantile(0.99, sum(rate(envoy_cluster_upstream_rq_time_bucket{cluster=~\"${wl_key}.*\"}[5m])) by (le)) > ${var.golden_signal_thresholds.latency_p99_ms}"
          for   = "2m"
          labels = {
            severity = "warning"
            service  = wl_key
            tier     = wl.abac_tier
          }
          annotations = {
            summary     = "P99 latency breach for service ${wl_key}"
            description = "Service ${wl_key} P99 latency exceeded ${var.golden_signal_thresholds.latency_p99_ms}ms over 5-minute window."
          }
        }
      ]
    },
    {
      name = "pontifex-golden-signals-errors"
      rules = [
        for wl_key, wl in var.workloads : {
          alert = "Workload5xxRateCritical"
          expr  = "sum(rate(envoy_cluster_upstream_rq_5xx{cluster=~\"${wl_key}.*\"}[5m])) / sum(rate(envoy_cluster_upstream_rq{cluster=~\"${wl_key}.*\"}[5m])) * 100 > ${var.golden_signal_thresholds.error_rate_percent}"
          for   = "1m"
          labels = {
            severity = "critical"
            service  = wl_key
            tier     = wl.abac_tier
          }
          annotations = {
            summary     = "Critical 5xx error rate on service ${wl_key}"
            description = "Service ${wl_key} error rate exceeded ${var.golden_signal_thresholds.error_rate_percent}%."
          }
        }
      ]
    },
    {
      name = "pontifex-golden-signals-saturation"
      rules = [
        for wl_key, wl in var.workloads : {
          alert = "ConnectionPoolSaturated"
          expr  = "envoy_cluster_upstream_cx_active{cluster=~\"${wl_key}.*\"} / ${wl.circuit_breaker.max_connections} * 100 > ${var.golden_signal_thresholds.saturation_percent}"
          for   = "3m"
          labels = {
            severity = "warning"
            service  = wl_key
          }
          annotations = {
            summary     = "Connection pool saturation for ${wl_key}"
            description = "Active connections reached ${var.golden_signal_thresholds.saturation_percent}% of circuit breaker limit."
          }
        }
      ]
    }
  ]
}

# Export Prometheus Alert Groups Manifest
resource "local_file" "golden_signals_manifest" {
  filename        = "${path.root}/.generated/observability/prometheus_golden_signals.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name  = var.fabric_name
    alert_groups = local.prometheus_alert_groups
  })
}

# Planetary Observability module outputs.
# Exposes Prometheus alerting rule groups, Alertmanager configurations, and synthetic probe matrices.

output "prometheus_alert_groups" {
  description = "Compiled Golden Signals Prometheus alerting rule groups."
  value       = local.prometheus_alert_groups
}

output "alertmanager_route_tree" {
  description = "Alertmanager routing trees and notification escalations."
  value       = local.alertmanager_route_tree
}

output "inhibition_rules" {
  description = "Alert inhibition rules suppressing downstream alert cascades."
  value       = local.inhibition_rules
}

output "tail_sampling_processors" {
  description = "OpenTelemetry adaptive tail-sampling configurations."
  value       = local.tail_sampling_processors
}

output "synthetic_probe_mesh" {
  description = "Full-mesh cross-region synthetic latency probing streams."
  value       = local.synthetic_probe_mesh
}

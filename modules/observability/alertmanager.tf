# Alertmanager routing tree, escalation paths, and alert inhibition hierarchies.
# Prevents notification storms during broad regional incidents or active chaos drills.

locals {
  # Alertmanager routing tree
  alertmanager_route_tree = {
    receiver        = "default-oncall-webhook"
    group_by        = ["alertname", "service", "region", "tier"]
    group_wait      = "10s"
    group_interval  = "1m"
    repeat_interval = "4h"
    routes = [
      {
        match = {
          severity = "critical"
        }
        receiver        = "pagerduty-high-urgency"
        repeat_interval = "30m"
        continue        = true
      },
      {
        match = {
          tier = "tier-0-critical"
        }
        receiver        = "security-incident-commander"
        repeat_interval = "15m"
        continue        = true
      },
      {
        match = {
          severity = "warning"
        }
        receiver        = "slack-mesh-telemetry"
        repeat_interval = "4h"
      }
    ]
  }

  # Alert Inhibition Rules (suppressing downstream noise during root-cause failures)
  inhibition_rules = [
    # Inhibit service alerts if entire region is partitioned or down
    {
      target_matchers = [
        {
          name  = "alertname"
          value = "WorkloadLatencyP99Breach|ConnectionPoolSaturated|Workload5xxRateCritical"
          type  = "regex"
        }
      ]
      source_matchers = [
        {
          name  = "alertname"
          value = "RegionPartitioned|RegionDown"
          type  = "regex"
        }
      ]
      equal_labels = ["region"]
    },
    # Inhibit warning error alert if critical error alert is already firing
    {
      target_matchers = [
        {
          name  = "alertname"
          value = "Workload5xxRateBreach"
          type  = "regex"
        }
      ]
      source_matchers = [
        {
          name  = "alertname"
          value = "Workload5xxRateCritical"
          type  = "regex"
        }
      ]
      equal_labels = ["service"]
    }
  ]
}

# Export Alertmanager Manifest
resource "local_file" "alertmanager_manifest" {
  filename        = "${path.root}/.generated/observability/alertmanager_routing.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name      = var.fabric_name
    routing_tree     = local.alertmanager_route_tree
    inhibition_rules = local.inhibition_rules
  })
}

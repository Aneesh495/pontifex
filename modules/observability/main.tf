# Planetary Observability and Telemetry subsystem entrypoint.
# Orchestrates Golden Signals Prometheus alerts, Alertmanager routing, and synthetic probes.

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

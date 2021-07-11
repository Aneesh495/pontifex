# Service mesh routing test verifying Envoy clusters, routes, circuit breakers, and rate limits.

run "verify_service_mesh_routing_summary" {
  command = plan

  variables {
    fabric_name = "pontifex-mesh-test"
    environment = "staging"
  }

  assert {
    condition     = output.service_mesh_summary.total_clusters >= 8
    error_message = "At least 8 Envoy upstream clusters must be configured across primary and canary tiers."
  }

  assert {
    condition     = output.service_mesh_summary.total_routes == 4
    error_message = "Four workload routes must be defined in the RDS route table."
  }

  assert {
    condition     = output.service_mesh_summary.circuit_breakers_on == 4
    error_message = "All four workloads must have active outlier detection and circuit breaking."
  }

  assert {
    condition     = output.service_mesh_summary.rate_limiting_active == 4
    error_message = "All four workloads must have distributed token-bucket rate limits."
  }
}

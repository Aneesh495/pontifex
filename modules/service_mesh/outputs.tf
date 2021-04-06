# L7 Service Mesh module outputs.
# Exposes Envoy CDS clusters, RDS canary routes, outlier detection, and rate limiting engines.

output "envoy_clusters" {
  description = "Compiled Envoy CDS upstream clusters across regions and canary tiers."
  value       = local.envoy_clusters
}

output "workload_routes" {
  description = "Envoy RDS route tables with weighted canary splits and retry policies."
  value       = local.workload_routes
}

output "circuit_breaker_engines" {
  description = "Outlier detection, consecutive 5xx ejection, and concurrency gates."
  value       = local.workload_circuit_breakers
}

output "rate_limit_descriptors" {
  description = "Distributed token-bucket rate limiting descriptor trees."
  value       = local.rate_limit_descriptors
}

output "fault_injection_profiles" {
  description = "L7 fault injection filters configured for chaos drills."
  value       = local.workload_fault_injections
}

# Autonomous Chaos Reactor module outputs.
# Exposes experiment catalogs, partition scenarios, link degradations, and hypothesis verifiers.

output "regional_isolation_experiments" {
  description = "Single-region catastrophic partition scenarios and quorum checks."
  value       = local.regional_isolation_experiments
}

output "transoceanic_partition" {
  description = "Multi-region trans-oceanic partition scenario."
  value       = local.transoceanic_partition
}

output "transit_link_degradations" {
  description = "Cross-region link latency, jitter, and packet drop simulation profiles."
  value       = local.transit_link_degradations
}

output "zone_evacuation_drills" {
  description = "Availability zone evacuation and traffic shift drill plans."
  value       = local.zone_evacuation_drills
}

output "canary_failure_drills" {
  description = "Canary failure injection drills verifying automated rollback triggers."
  value       = local.canary_failure_drills
}

output "steady_state_hypotheses" {
  description = "Formal steady-state hypothesis verifiers and SLO metric thresholds."
  value       = local.steady_state_hypotheses
}

output "emergency_rollback_latches" {
  description = "Automated tripwires and remediation actions for immediate drill rollback."
  value       = local.emergency_rollback_latches
}

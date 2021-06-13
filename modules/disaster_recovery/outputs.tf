# Disaster Recovery and Consensus module outputs.
# Exposes state machine transitions, promotion sequences, DNS failovers, and SLA scorecards.

output "failover_state_machine" {
  description = "Quorum consensus failover finite state machine."
  value       = local.failover_state_machine
}

output "promotion_ladder" {
  description = "Deterministic regional promotion sequence during primary failover."
  value       = local.flattened_promotion_ladder
}

output "dns_failover_records" {
  description = "Geo-distributed healthchecked DNS failover records."
  value       = local.dns_failover_records
}

output "snapshot_policies" {
  description = "Snapshot schedules, retention policies, and immutable WORM rules."
  value       = local.snapshot_policies
}

output "workload_pitr_coordinates" {
  description = "Point-in-Time Recovery continuous WAL archiving coordinates."
  value       = local.workload_pitr_coordinates
}

output "fabric_dr_scorecard" {
  description = "Overall fabric disaster recovery SLA verification scorecard."
  value       = local.fabric_dr_scorecard
}

output "workload_sla_evaluations" {
  description = "Workload-level RPO and RTO compliance evaluations."
  value       = local.workload_sla_evaluations
}

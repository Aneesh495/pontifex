# Disaster recovery SLA scorecard verification test.

run "verify_disaster_recovery_sla_scorecard" {
  command = plan

  variables {
    fabric_name = "pontifex-sla-test"
    environment = "staging"
  }

  assert {
    condition     = output.disaster_recovery_scorecard.all_workloads_compliant == true
    error_message = "All workloads must satisfy declarative RPO and RTO recovery targets."
  }

  assert {
    condition     = output.disaster_recovery_scorecard.rpo_target_seconds == 0
    error_message = "Root SLA RPO target must be 0 seconds."
  }

  assert {
    condition     = output.disaster_recovery_scorecard.rto_target_seconds == 30
    error_message = "Root SLA RTO target must be 30 seconds."
  }
}

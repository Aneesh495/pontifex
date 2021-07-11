# Parameter constraint enforcement test asserting proper rejection of invalid configurations.

run "reject_invalid_environment_tier" {
  command = plan

  variables {
    environment = "invalid-tier-name"
  }

  expect_failures = [
    var.environment
  ]
}

run "reject_excessive_disruption_budget" {
  command = plan

  variables {
    disruption_budget_percent = 75 # Max allowed is 50
  }

  expect_failures = [
    var.disruption_budget_percent
  ]
}

run "reject_invalid_supernet_cidr" {
  command = plan

  variables {
    global_supernet_cidr = "not-a-valid-ip-cidr/99"
  }

  expect_failures = [
    var.global_supernet_cidr
  ]
}

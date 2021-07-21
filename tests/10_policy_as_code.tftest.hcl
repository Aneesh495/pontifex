# Policy-as-Code test verifying planetary infrastructure policy compliance.

run "verify_policy_as_code_verdict" {
  command = plan

  variables {
    fabric_name          = "pontifex-policy-test"
    environment          = "production"
    global_supernet_cidr = "10.0.0.0/8"
  }

  assert {
    condition     = output.governance_policy_verdict.all_policies_passed == true
    error_message = "All planetary infrastructure policies must evaluate to PASSED."
  }

  assert {
    condition     = output.governance_policy_verdict.enforcement_mode == "STRICT_BLOCKING"
    error_message = "Policy enforcement mode must be STRICT_BLOCKING."
  }
}

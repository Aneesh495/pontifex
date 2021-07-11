# Chaos reactor and observability integration test verifying experiments, alerts, and probes.

run "verify_chaos_and_observability_manifests" {
  command = plan

  variables {
    fabric_name   = "pontifex-chaos-obs-test"
    environment   = "staging"
    chaos_enabled = true
  }

  assert {
    condition     = output.chaos_and_observability.active_chaos_experiments == 5
    error_message = "Five single-region isolation experiments must be configured for 5 regions."
  }

  assert {
    condition     = output.chaos_and_observability.alert_rule_groups == 3
    error_message = "Three Prometheus alert groups must be generated."
  }

  assert {
    condition     = output.chaos_and_observability.synthetic_probe_streams == 20 # 5 * 4 = 20 directional pairs
    error_message = "Twenty directional synthetic probe streams must be active across 5 regions."
  }
}

# OpenTelemetry adaptive tail-sampling configurations and distributed tracing policies.
# Maximizes diagnostic signal-to-noise by retaining 100% of anomalous and error-state traces.

locals {
  # OpenTelemetry collector tail-sampling processor policies
  tail_sampling_processors = {
    sampling_percentage_head = var.trace_sampling_rate * 100
    decision_wait_seconds    = 10
    num_traces               = 50000
    expected_new_traces_sec  = 2000
    policies = [
      # Always sample 100% of error traces
      {
        name          = "filter-errors-always-sample"
        type          = "status_code"
        status_code = {
          status_codes = ["ERROR", "UNSET"]
        }
      },
      # Always sample traces exceeding SLA latency threshold
      {
        name = "filter-latency-p95-exceeded"
        type = "latency"
        latency = {
          threshold_ms = 100
        }
      },
      # Always sample active chaos drill traces
      {
        name = "filter-chaos-experiment-traces"
        type = "string_attribute"
        string_attribute = {
          key                 = "x-pontifex-chaos"
          values              = ["active", "true"]
          enabled_regex_matching = false
        }
      },
      # Probabilistic background sampling for healthy traffic
      {
        name = "probabilistic-healthy-baseline"
        type = "probabilistic"
        probabilistic = {
          sampling_percentage = var.trace_sampling_rate * 100
        }
      }
    ]
    attribute_scrubbers = [
      "authorization",
      "proxy-authorization",
      "cookie",
      "set-cookie",
      "x-api-key"
    ]
  }
}

# Export OpenTelemetry Sampling Manifest
resource "local_file" "tracing_manifest" {
  filename        = "${path.root}/.generated/observability/opentelemetry_sampling.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name              = var.fabric_name
    tail_sampling_processors = local.tail_sampling_processors
  })
}

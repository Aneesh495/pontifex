# Declarative L7 fault injection filter chains for resilient chaos drills.
# Synthesizes header-activated latency delay and abort injection specifications.

locals {
  # Fault injection profiles synthesized for mesh workloads
  workload_fault_injections = {
    for wl_key, wl in var.workloads : wl_key => {
      filter_name = "envoy.filters.http.fault"
      workload    = wl_key
      namespace   = wl.namespace
      delay_fault = {
        percentage     = 5 # 5% injected during active chaos drills
        fixed_delay_ms = 150
        header_trigger = {
          name  = "x-pontifex-fault-delay"
          value = "active"
        }
      }
      abort_fault = {
        percentage  = 1 # 1% failure rate for resilience verification
        http_status = 503
        header_trigger = {
          name  = "x-pontifex-fault-abort"
          value = "active"
        }
      }
      max_active_faults = 100
    }
  }
}

# Export Fault Injection Manifest
resource "local_file" "fault_injection_manifest" {
  filename        = "${path.root}/.generated/mesh/fault_injection_filters.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name              = var.fabric_name
    total_fault_profiles     = length(local.workload_fault_injections)
    fault_injection_profiles = local.workload_fault_injections
  })
}

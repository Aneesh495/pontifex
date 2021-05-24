# Autonomous Chaos Reactor subsystem entrypoint.
# Orchestrates split-brain drills, link latency degradations, zone evictions, and safety latches.

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

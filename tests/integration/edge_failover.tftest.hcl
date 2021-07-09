# Integration test suite for dynamic edge failover and region priority reweighting.

run "verify_edge_failover_reweighting" {
  command = plan

  variables {
    fabric_name          = "pontifex-edge-failover-sim"
    environment          = "dr-simulation"
    global_supernet_cidr = "10.100.0.0/16"
    regions = {
      "us-east-primary" = {
        cloud_provider         = "aws"
        sovereign_jurisdiction = "us-fed"
        az_count               = 2
        anycast_enabled        = true
        failover_priority      = 1
        weight                 = 100
        egress_capacity_gbps   = 50
      }
      "us-west-standby" = {
        cloud_provider         = "aws"
        sovereign_jurisdiction = "us-fed"
        az_count               = 2
        anycast_enabled        = true
        failover_priority      = 2
        weight                 = 50
        egress_capacity_gbps   = 50
      }
    }
  }

  assert {
    condition     = output.fabric_metadata.region_count == 2
    error_message = "Failover topology must configure 2 regions."
  }

  assert {
    condition     = output.transit_topology.route_reflectors[0] == "us-east-primary"
    error_message = "Primary Route Reflector must be us-east-primary."
  }
}

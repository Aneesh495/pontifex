# Unit test suite for the planetary transit fabric module.
# Validates supernet allocation invariants, BGP peering graphs, and Anycast VIP assignments.

run "verify_transit_fabric_supernet_invariants" {
  command = plan

  module {
    source = "./modules/transit_fabric"
  }

  variables {
    fabric_name          = "pontifex-test-fabric"
    environment          = "staging"
    global_supernet_cidr = "10.0.0.0/8"
    asn_base             = 64512
    regions = {
      "us-east-1" = {
        cloud_provider         = "aws"
        sovereign_jurisdiction = "us-fed"
        az_count               = 3
        anycast_enabled        = true
        failover_priority      = 1
        weight                 = 100
        egress_capacity_gbps   = 100
      }
      "eu-central-1" = {
        cloud_provider         = "gcp"
        sovereign_jurisdiction = "eu-gdpr"
        az_count               = 3
        anycast_enabled        = true
        failover_priority      = 2
        weight                 = 90
        egress_capacity_gbps   = 100
      }
      "ap-southeast-1" = {
        cloud_provider         = "gcp"
        sovereign_jurisdiction = "apac-sg"
        az_count               = 2
        anycast_enabled        = false
        failover_priority      = 3
        weight                 = 60
        egress_capacity_gbps   = 50
      }
    }
  }

  # Assert regional supernets are partitioned cleanly into /12 blocks
  assert {
    condition     = output.regional_supernets["us-east-1"].supernet_cidr == "10.0.0.0/12"
    error_message = "US East 1 root supernet CIDR was not computed correctly."
  }

  assert {
    condition     = output.regional_supernets["eu-central-1"].supernet_cidr == "10.16.0.0/12"
    error_message = "EU Central 1 root supernet CIDR was not computed correctly."
  }

  assert {
    condition     = output.regional_supernets["ap-southeast-1"].supernet_cidr == "10.32.0.0/12"
    error_message = "APAC Southeast 1 root supernet CIDR was not computed correctly."
  }

  # Assert BGP Route Reflector election honors failover priority <= 2
  assert {
    condition     = contains(output.route_reflector_nodes, "us-east-1") && contains(output.route_reflector_nodes, "eu-central-1")
    error_message = "Regions with priority 1 and 2 must be elected as Route Reflectors."
  }

  assert {
    condition     = !contains(output.route_reflector_nodes, "ap-southeast-1")
    error_message = "Region with priority 3 must not be elected as Route Reflector."
  }

  # Assert BGP ASNs are monotonically incremented
  assert {
    condition     = output.regional_asns["us-east-1"] == 64512
    error_message = "Base ASN was not assigned to first regional index."
  }

  # Assert Anycast VIP synthesis
  assert {
    condition     = output.primary_anycast_vip != ""
    error_message = "Primary Anycast VIP must be populated."
  }
}

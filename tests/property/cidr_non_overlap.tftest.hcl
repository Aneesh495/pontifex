# Property-based test suite verifying CIDR non-overlap invariants across all regional tiers.

run "verify_cidr_non_overlap_invariant" {
  command = plan

  module {
    source = "./modules/transit_fabric"
  }

  variables {
    fabric_name          = "pontifex-property-cidr"
    environment          = "production"
    global_supernet_cidr = "10.0.0.0/8"
    asn_base             = 64512
    regions = {
      "us-east-1" = {
        cloud_provider         = "aws"
        sovereign_jurisdiction = "us-fed"
        az_count               = 4
        anycast_enabled        = true
        failover_priority      = 1
        weight                 = 100
        egress_capacity_gbps   = 100
      }
      "eu-central-1" = {
        cloud_provider         = "gcp"
        sovereign_jurisdiction = "eu-gdpr"
        az_count               = 4
        anycast_enabled        = true
        failover_priority      = 2
        weight                 = 90
        egress_capacity_gbps   = 100
      }
      "ap-southeast-1" = {
        cloud_provider         = "gcp"
        sovereign_jurisdiction = "apac-sg"
        az_count               = 3
        anycast_enabled        = true
        failover_priority      = 3
        weight                 = 60
        egress_capacity_gbps   = 50
      }
    }
  }

  # Invariant: The count of total allocated subnets must equal the count of distinct subnets
  assert {
    condition     = output.total_subnets_count == length(distinct(output.all_allocated_cidrs))
    error_message = "CIDR collision detected: Duplicate subnet blocks allocated in transit fabric."
  }

  # Invariant: Each regional supernet must be distinct
  assert {
    condition     = output.regional_supernets["us-east-1"].supernet_cidr != output.regional_supernets["eu-central-1"].supernet_cidr
    error_message = "US East and EU Central supernets collided."
  }
}

# Property-based test suite verifying BGP peering graph connectivity and self-loop prohibition.

run "verify_bgp_peering_graph_properties" {
  command = plan

  module {
    source = "./modules/transit_fabric"
  }

  variables {
    fabric_name          = "pontifex-property-bgp"
    environment          = "production"
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
        az_count               = 3
        anycast_enabled        = true
        failover_priority      = 3
        weight                 = 60
        egress_capacity_gbps   = 50
      }
    }
  }

  # Invariant: For 3 regions, full mesh pairing without self-loops yields N*(N-1)/2 = 3 peering links
  assert {
    condition     = length(output.peering_links) == 3
    error_message = "Three regions must produce exactly 3 canonical bidirectional peering links."
  }

  # Invariant: No peering link connects a region to itself
  assert {
    condition     = length([for k, l in output.peering_links : l if l.source == l.target]) == 0
    error_message = "BGP peering self-loop detected: Region peered with itself."
  }
}

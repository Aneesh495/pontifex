# Transit fabric topology test verifying BGP peering graphs, ASNs, and Anycast PoPs.

run "verify_transit_fabric_topology_manifests" {
  command = plan

  variables {
    fabric_name          = "pontifex-topology-test"
    environment          = "staging"
    global_supernet_cidr = "10.0.0.0/8"
  }

  assert {
    condition     = length(output.transit_topology.peering_links) == 10
    error_message = "Five sovereign regions in full-mesh must generate exactly 5*(5-1)/2 = 10 peering links."
  }

  assert {
    condition     = length(output.transit_topology.route_reflectors) == 2
    error_message = "Two sovereign regions must be elected as BGP Route Reflectors."
  }

  assert {
    condition     = length(output.transit_topology.anycast_pops) == 4
    error_message = "Four sovereign regions with anycast_enabled=true must instantiate Anycast PoPs."
  }
}

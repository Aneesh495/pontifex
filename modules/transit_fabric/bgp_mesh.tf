# Planetary BGP route reflector mesh, ECMP transit links, and path selection policies.
# Generates deterministic point-to-point interconnections, AS numbering, and peering matrices.

locals {
  # Deterministic Autonomous System Number (ASN) assignment per sovereign region
  regional_asns = {
    for idx, reg_key in local.sorted_region_keys : reg_key => (var.asn_base + idx)
  }

  # Route reflector election: Regions with failover priority 1 and 2 serve as Route Reflectors
  route_reflector_nodes = [
    for reg_key, reg in var.regions : reg_key
    if reg.failover_priority <= 2
  ]

  # Generate canonical bidirectional peering pairs between distinct regions
  # Filtering pairs where reg_a < reg_b guarantees exactly one bidirectional link per region pair
  canonical_peering_pairs = flatten([
    for idx_a, reg_a in local.sorted_region_keys : [
      for idx_b, reg_b in local.sorted_region_keys : {
        link_id     = "${reg_a}--${reg_b}"
        source      = reg_a
        target      = reg_b
        source_asn  = local.regional_asns[reg_a]
        target_asn  = local.regional_asns[reg_b]
        is_rr_peering = contains(local.route_reflector_nodes, reg_a) || contains(local.route_reflector_nodes, reg_b)
      }
      if idx_a < idx_b
    ]
  ])

  # Point-to-point /30 subnet allocation for each transit peering link
  # Sliced deterministically from the primary route reflector transit peering tier (/20)
  primary_transit_tier_cidr = local.regional_tiers[local.sorted_region_keys[0]].transit_peering.cidr

  peering_links = {
    for idx, pair in local.canonical_peering_pairs : pair.link_id => merge(pair, {
      link_index        = idx
      link_cidr         = cidrsubnet(local.primary_transit_tier_cidr, 10, idx)
      router_source_ip  = cidrhost(cidrsubnet(local.primary_transit_tier_cidr, 10, idx), 1)
      router_target_ip  = cidrhost(cidrsubnet(local.primary_transit_tier_cidr, 10, idx), 2)
      broadcast_ip      = cidrhost(cidrsubnet(local.primary_transit_tier_cidr, 10, idx), 3)
      mtu_bytes         = 9000 # Jumbo frames enabled for transit mesh interconnects
      keepalive_seconds = var.bgp_keepalive_seconds
      hold_seconds      = var.bgp_hold_seconds
      enable_bfd        = true # Bidirectional Forwarding Detection for sub-second failover
      bfd_min_rx_ms     = 100
      bfd_min_tx_ms     = 100
      bfd_multiplier    = 3
    })
  }

  # Directional BGP neighbor sessions from the perspective of each region
  regional_bgp_sessions = {
    for reg_key in local.sorted_region_keys : reg_key => [
      for link_id, link in local.peering_links : {
        session_id         = "${reg_key}->${link.source == reg_key ? link.target : link.source}"
        remote_region      = link.source == reg_key ? link.target : link.source
        remote_asn         = link.source == reg_key ? link.target_asn : link.source_asn
        local_interface_ip = link.source == reg_key ? link.router_source_ip : link.router_target_ip
        peer_interface_ip  = link.source == reg_key ? link.router_target_ip : link.router_source_ip
        link_cidr          = link.link_cidr
        is_route_reflector = contains(local.route_reflector_nodes, reg_key)
        is_client          = contains(local.route_reflector_nodes, reg_key) && !contains(local.route_reflector_nodes, link.source == reg_key ? link.target : link.source)
        local_preference   = var.regions[reg_key].failover_priority == 1 ? 200 : (var.regions[reg_key].failover_priority == 2 ? 150 : 100)
        med_metric         = max(10, 100 - var.regions[reg_key].weight)
        as_path_prepend    = var.regions[reg_key].failover_priority > 3 ? 2 : 0
        community_advertised = [
          "64512:${var.regions[reg_key].failover_priority * 100}",
          "64512:${var.regions[reg_key].weight}"
        ]
      }
      if link.source == reg_key || link.target == reg_key
    ]
  }

  # Equal-Cost Multi-Path (ECMP) routing bundle configurations
  ecmp_routing_bundles = {
    for reg_key, sessions in local.regional_bgp_sessions : reg_key => {
      max_paths         = 8
      load_balance_mode = "symmetric-5-tuple-hash"
      next_hops         = [for s in sessions : s.peer_interface_ip]
      total_routes      = length(sessions)
    }
  }
}

# Compile BGP mesh routing manifest
resource "local_file" "bgp_mesh_manifest" {
  filename        = "${path.root}/.generated/bgp_mesh_topology.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name           = var.fabric_name
    asn_base              = var.asn_base
    route_reflectors      = local.route_reflector_nodes
    regional_asns         = local.regional_asns
    total_peering_links   = length(local.peering_links)
    peering_links         = local.peering_links
    regional_bgp_sessions = local.regional_bgp_sessions
    ecmp_routing_bundles  = local.ecmp_routing_bundles
  })
}

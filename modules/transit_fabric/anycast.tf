# Planetary Anycast edge ingress tier, PoP routing vectors, and VIP synthesis.
# Provides low-latency edge ingress and automated BGP community route shedding.

locals {
  # Filter regions participating in the planetary Anycast ingress tier
  anycast_regions = [
    for reg_key, reg in var.regions : reg_key
    if reg.anycast_enabled
  ]

  # Global Anycast Virtual IP (VIP) pool
  # Sliced from the root supernet Anycast tier
  global_anycast_vip = cidrhost(local.regional_tiers[local.sorted_region_keys[0]].anycast_pop.cidr, 10)
  global_anycast_backup_vip = cidrhost(local.regional_tiers[local.sorted_region_keys[0]].anycast_pop.cidr, 11)

  # Regional Point-of-Presence (PoP) edge node configurations
  anycast_pop_nodes = {
    for idx, reg_key in local.anycast_regions : reg_key => {
      pop_identifier      = "pop-${reg_key}"
      region_key          = reg_key
      cloud_provider      = var.regions[reg_key].cloud_provider
      jurisdiction        = var.regions[reg_key].sovereign_jurisdiction
      primary_vip         = local.global_anycast_vip
      backup_vip          = local.global_anycast_backup_vip
      local_gateway_ip    = cidrhost(local.regional_tiers[reg_key].anycast_pop.cidr, 1)
      local_ingress_ip    = cidrhost(local.regional_tiers[reg_key].anycast_pop.cidr, 5 + idx)
      bgp_asn             = local.regional_asns[reg_key]
      bgp_community_active = "64512:10"
      bgp_community_shed   = "64512:666" # Blackhole community for emergency traffic shedding
      vrrp_group_id       = 100 + idx
      vrrp_priority       = 250 - (var.regions[reg_key].failover_priority * 20)
      vrrp_advert_int_sec = 1
      geo_coordinates = {
        "us-east-1"      = { lat = 38.0,  lon = -77.5, continent = "NA" }
        "us-west-2"      = { lat = 45.5,  lon = -122.6, continent = "NA" }
        "eu-central-1"   = { lat = 50.1,  lon = 8.6,   continent = "EU" }
        "eu-west-1"      = { lat = 53.3,  lon = -6.2,  continent = "EU" }
        "ap-southeast-1" = { lat = 1.35,  lon = 103.8, continent = "AS" }
      }[reg_key]
      health_check = {
        probe_protocol    = "tcp"
        probe_port        = 443
        interval_seconds  = 5
        timeout_seconds   = 2
        unhealthy_threshold = 2
        healthy_threshold   = 3
      }
      ddos_mitigation = {
        syn_flood_protection = true
        rate_limit_per_client_ip = 5000 # requests per minute
        burst_allowance          = 1000
      }
    }
  }

  # Geo-DNS proximity routing map
  geo_routing_weights = {
    for reg_key in local.anycast_regions : reg_key => {
      weight             = var.regions[reg_key].weight
      failover_priority  = var.regions[reg_key].failover_priority
      assigned_continents = [local.anycast_pop_nodes[reg_key].geo_coordinates.continent]
    }
  }
}

# Compile Anycast edge manifest
resource "local_file" "anycast_manifest" {
  filename        = "${path.root}/.generated/anycast_routing_manifest.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name         = var.fabric_name
    primary_anycast_vip = local.global_anycast_vip
    backup_anycast_vip  = local.global_anycast_backup_vip
    active_pop_count    = length(local.anycast_pop_nodes)
    pop_nodes           = local.anycast_pop_nodes
    geo_routing_weights = local.geo_routing_weights
  })
}

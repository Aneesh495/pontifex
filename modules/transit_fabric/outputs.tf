# Transit fabric module outputs.
# Exposes compiled network topologies, CIDR tiers, BGP peering graphs, and Anycast VIPs.

output "regional_supernets" {
  description = "Allocated /12 regional supernets partitioned by sovereign cloud region."
  value       = local.regional_supernets
}

output "regional_tiers" {
  description = "Functional network tiers (ingress, compute, data, transit, anycast) per region."
  value       = local.regional_tiers
}

output "az_subnets" {
  description = "Subnets subdivided across availability zones per region."
  value       = local.az_subnets
}

output "all_allocated_cidrs" {
  description = "Flat list of all allocated subnet CIDR blocks across the entire fabric."
  value       = local.all_allocated_cidrs
}

output "total_subnets_count" {
  description = "Total count of allocated subnets across all regions and tiers."
  value       = local.total_subnets_count
}

output "regional_asns" {
  description = "Map of Autonomous System Numbers assigned to each sovereign region."
  value       = local.regional_asns
}

output "route_reflector_nodes" {
  description = "List of sovereign regions elected as BGP Route Reflectors."
  value       = local.route_reflector_nodes
}

output "peering_links" {
  description = "Planetary BGP transit peering links with point-to-point /30 allocations."
  value       = local.peering_links
}

output "regional_bgp_sessions" {
  description = "Directional BGP neighbor sessions per sovereign region."
  value       = local.regional_bgp_sessions
}

output "ecmp_routing_bundles" {
  description = "Equal-Cost Multi-Path routing bundles configured for symmetric load balancing."
  value       = local.ecmp_routing_bundles
}

output "primary_anycast_vip" {
  description = "Planetary Anycast VIP address for global edge ingress."
  value       = local.global_anycast_vip
}

output "anycast_pop_nodes" {
  description = "Edge Point-of-Presence node definitions participating in Anycast routing."
  value       = local.anycast_pop_nodes
}

output "regional_nat_gateways" {
  description = "Sovereign egress NAT gateways configured per availability zone."
  value       = local.regional_nat_gateways
}

output "sovereign_egress_policies" {
  description = "Data residency and sovereign egress policies by region."
  value       = local.sovereign_egress_policies
}

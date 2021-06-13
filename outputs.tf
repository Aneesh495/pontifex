# Root output declarations for Pontifex planetary fabric.
# Synthesizes unified infrastructure state, endpoints, trust anchors, and reliability metrics.

output "fabric_metadata" {
  description = "Planetary transit fabric deployment metadata and topology overview."
  value = {
    fabric_name       = var.fabric_name
    environment       = var.environment
    supernet_cidr     = var.global_supernet_cidr
    active_regions    = keys(var.regions)
    region_count      = length(var.regions)
    total_subnets     = module.transit_fabric.total_subnets_count
    primary_anycast   = module.transit_fabric.primary_anycast_vip
    trust_domain      = "pontifex.internal"
    chaos_enabled     = var.chaos_enabled
  }
}

output "transit_topology" {
  description = "Compiled transit topology with BGP mesh and regional subnets."
  value = {
    regional_supernets = module.transit_fabric.regional_supernets
    peering_links      = module.transit_fabric.peering_links
    route_reflectors   = module.transit_fabric.route_reflector_nodes
    anycast_pops       = module.transit_fabric.anycast_pop_nodes
  }
}

output "security_pki" {
  description = "Cryptographic trust anchors, trust bundles, and audit verification."
  value = {
    root_primary_fingerprint   = module.crypto_pki.trust_anchor_fingerprints.root_primary
    root_secondary_fingerprint = module.crypto_pki.trust_anchor_fingerprints.root_secondary
    trust_bundle_pem           = module.crypto_pki.planetary_trust_bundle_pem
    latest_audit_block_hash    = module.zero_trust.latest_audit_block_id
  }
}

output "service_mesh_summary" {
  description = "Envoy upstream clusters and dynamic canary routes."
  value = {
    total_clusters       = length(module.service_mesh.envoy_clusters)
    total_routes         = length(module.service_mesh.workload_routes)
    circuit_breakers_on  = length(module.service_mesh.circuit_breaker_engines)
    rate_limiting_active = length(module.service_mesh.rate_limit_descriptors)
  }
}

output "data_plane_summary" {
  description = "Active-active storage partitions and consistent hashing cache ring."
  value = {
    read_quorum_size    = module.data_plane.read_quorum_size
    write_quorum_size   = module.data_plane.write_quorum_size
    cache_virtual_nodes = module.data_plane.total_cache_virtual_nodes
    wal_topics          = keys(module.data_plane.wal_topics)
  }
}

output "chaos_and_observability" {
  description = "Resilience simulation profiles and Golden Signals alert configurations."
  value = {
    active_chaos_experiments = length(module.chaos_reactor.regional_isolation_experiments)
    alert_rule_groups        = length(module.observability.prometheus_alert_groups)
    synthetic_probe_streams  = length(module.observability.synthetic_probe_mesh)
  }
}

output "disaster_recovery_scorecard" {
  description = "Planetary RPO/RTO SLA verification scorecard."
  value = module.disaster_recovery.fabric_dr_scorecard
}

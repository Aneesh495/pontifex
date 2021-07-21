# Pontifex: Planetary-Scale Declarative Transit Fabric and Zero-Trust Mesh Hypervisor.
# Root composition module orchestrating all eight sovereign infrastructure subsystems.

# 1. Planetary Sovereign Transit Fabric
module "transit_fabric" {
  source = "./modules/transit_fabric"

  fabric_name           = var.fabric_name
  environment           = var.environment
  global_supernet_cidr  = var.global_supernet_cidr
  asn_base              = var.asn_base
  regions               = var.regions
  bgp_keepalive_seconds = 30
  bgp_hold_seconds      = 90
  enable_flow_logs      = true
}

# 2. Cryptographic Zero-Trust PKI and SPIFFE Hypervisor
module "crypto_pki" {
  source = "./modules/crypto_pki"

  fabric_name                    = var.fabric_name
  environment                    = var.environment
  regions                        = var.regions
  workloads                      = var.workloads
  trust_domain                   = "pontifex.internal"
  key_algorithm                  = "ECDSA"
  ecdsa_curve                    = "P384"
  root_ca_validity_hours         = 87600 # 10 years
  intermediate_ca_validity_hours = 43800 # 5 years
  leaf_svid_validity_hours       = 720   # 30 days
}

# 3. L7 Service Mesh and Traffic Director
module "service_mesh" {
  source = "./modules/service_mesh"

  fabric_name              = var.fabric_name
  environment              = var.environment
  regions                  = var.regions
  workloads                = var.workloads
  connect_timeout_ms       = 250
  max_request_headers_kb   = 64
  enable_envoy_access_logs = true
}

# 4. Zero-Trust Policy Matrix and Secret Governance
module "zero_trust" {
  source = "./modules/zero_trust"

  fabric_name                    = var.fabric_name
  environment                    = var.environment
  regions                        = var.regions
  workloads                      = var.workloads
  jwt_issuer                     = "https://auth.pontifex.internal"
  secret_rotation_interval_hours = 24
  enable_audit_tamper_evidence   = true
}

# 5. Active-Active Planetary Data Plane
module "data_plane" {
  source = "./modules/data_plane"

  fabric_name                  = var.fabric_name
  environment                  = var.environment
  regions                      = var.regions
  workloads                    = var.workloads
  replication_sync_interval_ms = 100
  cache_virtual_nodes          = 64
  wal_segment_size_mb          = 64
  wal_retention_hours          = 168
}

# 6. Autonomous Chaos Reactor
module "chaos_reactor" {
  source = "./modules/chaos_reactor"

  fabric_name                 = var.fabric_name
  environment                 = var.environment
  regions                     = var.regions
  workloads                   = var.workloads
  chaos_enabled               = var.chaos_enabled
  disruption_budget_percent   = var.disruption_budget_percent
  max_concurrent_experiments  = 2
  auto_rollback_on_slo_breach = true
}

# 7. Planetary Observability and Telemetry
module "observability" {
  source = "./modules/observability"

  fabric_name                  = var.fabric_name
  environment                  = var.environment
  regions                      = var.regions
  workloads                    = var.workloads
  golden_signal_thresholds     = var.golden_signal_thresholds
  trace_sampling_rate          = 0.05
  synthetic_probe_interval_sec = 10
}

# 8. Disaster Recovery and Consensus Engine
module "disaster_recovery" {
  source = "./modules/disaster_recovery"

  fabric_name           = var.fabric_name
  environment           = var.environment
  regions               = var.regions
  workloads             = var.workloads
  disaster_recovery_sla = var.disaster_recovery_sla
  dns_ttl_seconds       = 60
}

# 9. Declarative Policy-as-Code Governance
module "policies" {
  source = "./policies"

  fabric_name          = var.fabric_name
  environment          = var.environment
  global_supernet_cidr = var.global_supernet_cidr
  regions              = var.regions
  workloads            = var.workloads
}

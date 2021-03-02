# Sovereign egress NAT gateway topologies, deterministic IP pools, and flow logging.
# Enforces regional data residency boundaries and outbound traffic auditing.

locals {
  # Deterministic NAT gateway configuration per regional availability zone
  regional_nat_gateways = {
    for reg_key, tiers in local.az_subnets : reg_key => [
      for az_idx, pub_sub in tiers.public_subnets : {
        gateway_id             = "nat-${pub_sub.az_name}"
        region_key             = reg_key
        az_name                = pub_sub.az_name
        az_index               = az_idx
        cloud_provider         = var.regions[reg_key].cloud_provider
        jurisdiction           = var.regions[reg_key].sovereign_jurisdiction
        allocation_subnet_cidr = pub_sub.cidr_block
        nat_public_ip          = cidrhost(pub_sub.cidr_block, 10 + az_idx)
        internal_interface_ip  = cidrhost(pub_sub.cidr_block, 2)
        egress_capacity_gbps   = floor(var.regions[reg_key].egress_capacity_gbps / var.regions[reg_key].az_count)
        ha_standby_az          = tiers.public_subnets[(az_idx + 1) % length(tiers.public_subnets)].az_name
        flow_log_enabled       = var.enable_flow_logs
      }
    ]
  }

  # Flattened list of all NAT gateway endpoints across the planetary fabric
  all_nat_gateways = flatten([
    for reg_key, gateways in local.regional_nat_gateways : gateways
  ])

  # Sovereign data perimeter rules: Prevent unencrypted egress from sovereign-data tier
  sovereign_egress_policies = {
    for reg_key, reg in var.regions : reg_key => {
      jurisdiction         = reg.sovereign_jurisdiction
      allow_public_egress  = reg.sovereign_jurisdiction != "us-fed" # FedRAMP isolation requires strict zero-public-egress
      cross_region_transit = "mtls-ipsec-enforced"
      flow_log_sampling    = reg.sovereign_jurisdiction == "eu-gdpr" ? 1.0 : 0.5 # 100% flow audit for GDPR compliance
      drop_invalid_packets = true
    }
  }
}

# Compile Egress NAT gateway manifest
resource "local_file" "egress_manifest" {
  filename        = "${path.root}/.generated/egress_gateways_manifest.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name               = var.fabric_name
    total_nat_gateways        = length(local.all_nat_gateways)
    gateways_by_region        = local.regional_nat_gateways
    sovereign_egress_policies = local.sovereign_egress_policies
  })
}

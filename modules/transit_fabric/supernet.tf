# Recursive supernet allocation and deterministic subnet tier partitioning.
# Computes non-overlapping CIDR blocks across sovereign cloud regions and availability zones.

locals {
  # Sort regional identifiers to ensure deterministic CIDR allocation indices
  sorted_region_keys = sort(keys(var.regions))

  # Regional root allocation: Partition /8 into /12 regional supernets (up to 16 regions)
  # cidrsubnet("10.0.0.0/8", 4, index) yields 10.0.0.0/12, 10.16.0.0/12, 10.32.0.0/12, etc.
  regional_supernets = {
    for idx, reg_key in local.sorted_region_keys : reg_key => {
      region_key             = reg_key
      region_index           = idx
      cloud_provider         = var.regions[reg_key].cloud_provider
      sovereign_jurisdiction = var.regions[reg_key].sovereign_jurisdiction
      az_count               = var.regions[reg_key].az_count
      supernet_cidr          = cidrsubnet(var.global_supernet_cidr, 4, idx)
      supernet_netmask       = cidrnetmask(cidrsubnet(var.global_supernet_cidr, 4, idx))
      network_address        = cidrhost(cidrsubnet(var.global_supernet_cidr, 4, idx), 0)
      transit_gateway_ip     = cidrhost(cidrsubnet(var.global_supernet_cidr, 4, idx), 1)
    }
  }

  # Partition each regional /12 supernet into functional network tiers:
  # Tier 0 (Public Ingress): /16 (prefix +4) at index 0
  # Tier 1 (Private Compute): /14 (prefix +2) at index 1
  # Tier 2 (Sovereign Data): /15 (prefix +3) at index 4
  # Tier 3 (Transit Peering): /20 (prefix +8) at index 240
  # Tier 4 (Anycast PoP): /24 (prefix +12) at index 4000
  regional_tiers = {
    for reg_key, reg in local.regional_supernets : reg_key => {
      public_ingress = {
        tier_name = "public-ingress"
        cidr      = cidrsubnet(reg.supernet_cidr, 4, 0)
        netmask   = cidrnetmask(cidrsubnet(reg.supernet_cidr, 4, 0))
        purpose   = "L4/L7 edge balancers, external NAT gateways, and public entrypoints"
      }
      private_compute = {
        tier_name = "private-compute"
        cidr      = cidrsubnet(reg.supernet_cidr, 2, 1)
        netmask   = cidrnetmask(cidrsubnet(reg.supernet_cidr, 2, 1))
        purpose   = "Mesh proxy sidecars, application microservices, and workload nodes"
      }
      sovereign_data = {
        tier_name = "sovereign-data"
        cidr      = cidrsubnet(reg.supernet_cidr, 3, 4)
        netmask   = cidrnetmask(cidrsubnet(reg.supernet_cidr, 3, 4))
        purpose   = "Active-active storage partitions, cache clusters, and WAL ledgers"
      }
      transit_peering = {
        tier_name = "transit-peering"
        cidr      = cidrsubnet(reg.supernet_cidr, 8, 240)
        netmask   = cidrnetmask(cidrsubnet(reg.supernet_cidr, 8, 240))
        purpose   = "Cross-region point-to-point transit interconnects and BGP interfaces"
      }
      anycast_pop = {
        tier_name = "anycast-pop"
        cidr      = cidrsubnet(reg.supernet_cidr, 12, 4000)
        netmask   = cidrnetmask(cidrsubnet(reg.supernet_cidr, 12, 4000))
        purpose   = "BGP Anycast VIP route injection and local edge accelerator pools"
      }
    }
  }

  # Subdivide each regional tier across availability zones
  az_subnets = {
    for reg_key, reg in local.regional_supernets : reg_key => {
      public_subnets = [
        for az_idx in range(reg.az_count) : {
          az_name            = "${reg_key}-${element(["a", "b", "c", "d", "e", "f"], az_idx)}"
          az_index           = az_idx
          tier               = "public-ingress"
          cidr_block         = cidrsubnet(local.regional_tiers[reg_key].public_ingress.cidr, 4, az_idx)
          netmask            = cidrnetmask(cidrsubnet(local.regional_tiers[reg_key].public_ingress.cidr, 4, az_idx))
          gateway_ip         = cidrhost(cidrsubnet(local.regional_tiers[reg_key].public_ingress.cidr, 4, az_idx), 1)
          cloud_reserved_ips = [for host_idx in range(1, 5) : cidrhost(cidrsubnet(local.regional_tiers[reg_key].public_ingress.cidr, 4, az_idx), host_idx)]
        }
      ]
      compute_subnets = [
        for az_idx in range(reg.az_count) : {
          az_name            = "${reg_key}-${element(["a", "b", "c", "d", "e", "f"], az_idx)}"
          az_index           = az_idx
          tier               = "private-compute"
          cidr_block         = cidrsubnet(local.regional_tiers[reg_key].private_compute.cidr, 4, az_idx)
          netmask            = cidrnetmask(cidrsubnet(local.regional_tiers[reg_key].private_compute.cidr, 4, az_idx))
          gateway_ip         = cidrhost(cidrsubnet(local.regional_tiers[reg_key].private_compute.cidr, 4, az_idx), 1)
          cloud_reserved_ips = [for host_idx in range(1, 5) : cidrhost(cidrsubnet(local.regional_tiers[reg_key].private_compute.cidr, 4, az_idx), host_idx)]
        }
      ]
      data_subnets = [
        for az_idx in range(reg.az_count) : {
          az_name            = "${reg_key}-${element(["a", "b", "c", "d", "e", "f"], az_idx)}"
          az_index           = az_idx
          tier               = "sovereign-data"
          cidr_block         = cidrsubnet(local.regional_tiers[reg_key].sovereign_data.cidr, 4, az_idx)
          netmask            = cidrnetmask(cidrsubnet(local.regional_tiers[reg_key].sovereign_data.cidr, 4, az_idx))
          gateway_ip         = cidrhost(cidrsubnet(local.regional_tiers[reg_key].sovereign_data.cidr, 4, az_idx), 1)
          cloud_reserved_ips = [for host_idx in range(1, 5) : cidrhost(cidrsubnet(local.regional_tiers[reg_key].sovereign_data.cidr, 4, az_idx), host_idx)]
        }
      ]
    }
  }

  # Flattened inventory of every allocated subnet in the planetary fabric for invariant verification
  all_allocated_cidrs = flatten([
    for reg_key, tiers in local.az_subnets : concat(
      [for s in tiers.public_subnets : s.cidr_block],
      [for s in tiers.compute_subnets : s.cidr_block],
      [for s in tiers.data_subnets : s.cidr_block]
    )
  ])

  # Unique count validation assertion
  total_subnets_count  = length(local.all_allocated_cidrs)
  unique_subnets_count = length(distinct(local.all_allocated_cidrs))
}

# Output compiled supernet map for external consumers and automated inspection
resource "local_file" "supernet_manifest" {
  filename        = "${path.root}/.generated/supernet_manifest.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name        = var.fabric_name
    environment        = var.environment
    root_supernet_cidr = var.global_supernet_cidr
    total_regions      = length(local.sorted_region_keys)
    total_subnets      = local.total_subnets_count
    subnets_are_unique = local.total_subnets_count == local.unique_subnets_count
    regional_supernets = local.regional_supernets
    regional_tiers     = local.regional_tiers
    availability_zones = local.az_subnets
  })
}

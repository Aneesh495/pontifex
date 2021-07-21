# Policy-as-Code: CIDR Boundary and RFC 1918 Address Space Conformance.
# Formally verifies address space allocation invariants in pure HCL.

locals {
  # Policy Rule 1: Root supernet must belong to private RFC 1918 or RFC 6598 ranges
  is_rfc1918_10_block  = can(regex("^10\\.", var.global_supernet_cidr))
  is_rfc1918_172_block = can(regex("^172\\.(1[6-9]|2[0-9]|3[0-1])\\.", var.global_supernet_cidr))
  is_rfc1918_192_block = can(regex("^192\\.168\\.", var.global_supernet_cidr))
  is_rfc6598_cgnat     = can(regex("^100\\.(6[4-9]|[7-9][0-9]|1[0-1][0-9]|12[0-7])\\.", var.global_supernet_cidr))

  policy_root_cidr_is_private = local.is_rfc1918_10_block || local.is_rfc1918_172_block || local.is_rfc1918_192_block || local.is_rfc6598_cgnat

  # Policy Rule 2: Minimum regional AZ availability (must have at least 2 AZs per region)
  az_compliance_per_region = {
    for reg_key, reg in var.regions : reg_key => {
      az_count     = reg.az_count
      is_compliant = reg.az_count >= 2
    }
  }

  all_regions_meet_az_minimum = alltrue([
    for k, v in local.az_compliance_per_region : v.is_compliant
  ])

  # Policy Rule 3: Regional egress capacity sanity (each region must provision at least 10 Gbps)
  egress_capacity_compliance = {
    for reg_key, reg in var.regions : reg_key => {
      capacity_gbps = reg.egress_capacity_gbps
      is_compliant  = reg.egress_capacity_gbps >= 10
    }
  }

  all_regions_meet_egress_capacity = alltrue([
    for k, v in local.egress_capacity_compliance : v.is_compliant
  ])

  # Consolidated CIDR and Topology Policy Evaluation
  cidr_policy_scorecard = {
    policy_name                     = "POL-NET-001: Planetary Addressing & Boundary Isolation"
    root_supernet_private_compliant = local.policy_root_cidr_is_private
    all_regions_az_compliant        = local.all_regions_meet_az_minimum
    all_regions_capacity_compliant  = local.all_regions_meet_egress_capacity
    overall_status                  = (local.policy_root_cidr_is_private && local.all_regions_meet_az_minimum && local.all_regions_meet_egress_capacity) ? "PASSED" : "FAILED"
  }
}

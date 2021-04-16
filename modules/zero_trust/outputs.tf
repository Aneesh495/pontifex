# Zero-Trust Policy and Security module outputs.
# Exposes RBAC lattice, JWT auth configs, network microsegmentation, and audit chain.

output "rbac_roles" {
  description = "Planetary RBAC role definitions and action whitelists."
  value       = local.rbac_roles
}

output "abac_tiers" {
  description = "Attribute-Based Access Control security tiers."
  value       = local.abac_tiers
}

output "workload_abac_bindings" {
  description = "Workload security tier and ABAC policy bindings."
  value       = local.workload_abac_bindings
}

output "jwt_providers" {
  description = "Configured OpenID Connect JWT token providers."
  value       = local.jwt_providers
}

output "jwt_requirement_rules" {
  description = "Route-level JWT authentication and claim requirement rules."
  value       = local.jwt_requirement_rules
}

output "namespace_security_policies" {
  description = "Default-deny Layer 3/4 network microsegmentation policies."
  value       = local.namespace_security_policies
}

output "secret_rotation_records" {
  description = "Cryptographic secret rotation records and active lease metadata."
  value       = local.secret_rotation_records
}

output "audit_chain" {
  description = "Cryptographically chained tamper-evident audit ledger blocks."
  value       = local.audit_chain
}

output "latest_audit_block_id" {
  description = "SHA-256 block hash of the latest verified audit record."
  value       = local.block_4_block_hash
}

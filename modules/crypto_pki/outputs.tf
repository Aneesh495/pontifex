# Cryptographic Zero-Trust PKI module outputs.
# Exposes generated certificates, trust bundles, fingerprints, and SPIFFE matrices.

output "root_primary_cert_pem" {
  description = "Planetary Primary Root CA certificate in PEM format."
  value       = tls_self_signed_cert.root_primary.cert_pem
}

output "root_secondary_cert_pem" {
  description = "Planetary Secondary Standby Root CA certificate in PEM format."
  value       = tls_self_signed_cert.root_secondary.cert_pem
}

output "regional_intermediate_certs" {
  description = "Map of sovereign regional intermediate CA certificates in PEM format."
  value       = { for k, v in tls_locally_signed_cert.regional_intermediate : k => v.cert_pem }
}

output "workload_svid_certs" {
  description = "Map of workload SPIFFE SVID certificates in PEM format."
  value       = { for k, v in tls_locally_signed_cert.workload_svid : k => v.cert_pem }
}

output "planetary_trust_bundle_pem" {
  description = "Combined planetary trust bundle including Root and Intermediate CAs."
  value       = local.planetary_trust_bundle_pem
}

output "trust_anchor_fingerprints" {
  description = "Cryptographic SHA-256 fingerprints of all root and intermediate trust anchors."
  value       = local.trust_anchor_fingerprints
}

output "spiffe_authorization_matrix" {
  description = "Zero-trust peer-to-peer SPIFFE authorization matrix."
  value       = local.spiffe_authz_matrix
}

output "tls_profile" {
  description = "Strict TLS 1.3 cryptographic profile specifications."
  value       = local.tls_profile
}

output "revocation_endpoints" {
  description = "Planetary CRL and OCSP revocation endpoints."
  value       = local.revocation_endpoints
}

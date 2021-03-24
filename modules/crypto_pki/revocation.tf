# Certificate Revocation List (CRL) distribution, OCSP stapling, and planetary trust bundle.
# Compiles verified cryptographic trust bundles and revocation infrastructure endpoints.

locals {
  # Sort regional keys for deterministic iteration
  sorted_region_keys = sort(keys(var.regions))

  # Concatenate Root CAs and all Regional Intermediate CAs into the planetary trust bundle
  intermediate_cert_list = [
    for reg_key, cert in tls_locally_signed_cert.regional_intermediate : cert.cert_pem
  ]

  planetary_trust_bundle_pem = join("\n", concat(
    [tls_self_signed_cert.root_primary.cert_pem],
    [tls_self_signed_cert.root_secondary.cert_pem],
    local.intermediate_cert_list
  ))

  # Compute cryptographic SHA-256 fingerprints for trust anchor verification
  trust_anchor_fingerprints = {
    root_primary   = sha256(tls_self_signed_cert.root_primary.cert_pem)
    root_secondary = sha256(tls_self_signed_cert.root_secondary.cert_pem)
    regional_intermediates = {
      for reg_key, cert in tls_locally_signed_cert.regional_intermediate : reg_key => sha256(cert.cert_pem)
    }
  }

  # Revocation and OCSP distribution endpoints
  revocation_endpoints = {
    root_crl_distribution_point = "http://crl.${var.trust_domain}/root.crl"
    regional_crl_endpoints = {
      for reg_key in local.sorted_region_keys : reg_key => "http://crl.${var.trust_domain}/intermediates/${reg_key}.crl"
    }
    ocsp_responder_url         = "http://ocsp.${var.trust_domain}/"
    crl_refresh_interval_sec   = 3600
    ocsp_cache_duration_sec    = 7200
  }
}

# Export Planetary Trust Bundle to filesystem
resource "local_file" "planetary_trust_bundle" {
  filename        = "${path.root}/.generated/pki/planetary_trust_bundle.pem"
  file_permission = "0644"
  content         = local.planetary_trust_bundle_pem
}

# Export Revocation and Fingerprint Manifest
resource "local_file" "revocation_manifest" {
  filename        = "${path.root}/.generated/pki/revocation_manifest.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name               = var.fabric_name
    trust_anchor_fingerprints = local.trust_anchor_fingerprints
    revocation_endpoints      = local.revocation_endpoints
  })
}

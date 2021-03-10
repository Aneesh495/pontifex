# Sovereign regional intermediate certificate authorities.
# Issues scoped issuing credentials per cloud jurisdiction signed by the Root CA.

# Regional Intermediate CA Private Keys
resource "tls_private_key" "regional_intermediate" {
  for_each = var.regions

  algorithm   = var.key_algorithm
  ecdsa_curve = var.key_algorithm == "ECDSA" ? var.ecdsa_curve : null
  rsa_bits    = var.key_algorithm == "RSA" ? 4096 : null
}

# Certificate Signing Requests for Regional Intermediate CAs
resource "tls_cert_request" "regional_intermediate" {
  for_each = var.regions

  private_key_pem = tls_private_key.regional_intermediate[each.key].private_key_pem

  subject {
    common_name         = "Pontifex Regional CA (${each.key})"
    organization        = "Pontifex Trust Network"
    organizational_unit = each.value.sovereign_jurisdiction
    country             = "US"
    locality            = each.key
  }
}

# Sign Regional Intermediate CAs using Primary Root CA
resource "tls_locally_signed_cert" "regional_intermediate" {
  for_each = var.regions

  cert_request_pem   = tls_cert_request.regional_intermediate[each.key].cert_request_pem
  ca_private_key_pem = tls_private_key.root_primary.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_primary.cert_pem

  validity_period_hours = var.intermediate_ca_validity_hours
  early_renewal_hours   = 4380 # Renew 6 months before expiry
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature"
  ]
}

# Export Regional Intermediate Certificates
resource "local_file" "regional_intermediate_certs" {
  for_each = var.regions

  filename        = "${path.root}/.generated/pki/intermediates/ca_${each.key}.crt"
  file_permission = "0644"
  content         = tls_locally_signed_cert.regional_intermediate[each.key].cert_pem
}

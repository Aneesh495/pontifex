# Planetary Root Certificate Authority generation and trust anchor synthesis.
# Provides dual-root cryptographic isolation with ECDSA P-384 key material.

# Primary Root CA Private Key
resource "tls_private_key" "root_primary" {
  algorithm   = var.key_algorithm
  ecdsa_curve = var.key_algorithm == "ECDSA" ? var.ecdsa_curve : null
  rsa_bits    = var.key_algorithm == "RSA" ? 4096 : null
}

# Primary Root CA Self-Signed Trust Anchor Certificate
resource "tls_self_signed_cert" "root_primary" {
  private_key_pem = tls_private_key.root_primary.private_key_pem

  subject {
    common_name         = "Pontifex Planetary Root CA Primary"
    organization        = "Pontifex Trust Network"
    organizational_unit = "Planetary Cryptographic Infrastructure"
    country             = "US"
    locality            = "Global"
  }

  validity_period_hours = var.root_ca_validity_hours
  early_renewal_hours   = 8760 # Renew 1 year before expiry
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature"
  ]
}

# Secondary Standby Root CA Private Key (for planned rotation and disaster rollover)
resource "tls_private_key" "root_secondary" {
  algorithm   = var.key_algorithm
  ecdsa_curve = var.key_algorithm == "ECDSA" ? var.ecdsa_curve : null
  rsa_bits    = var.key_algorithm == "RSA" ? 4096 : null
}

# Secondary Standby Root CA Certificate
resource "tls_self_signed_cert" "root_secondary" {
  private_key_pem = tls_private_key.root_secondary.private_key_pem

  subject {
    common_name         = "Pontifex Planetary Root CA Secondary (Standby)"
    organization        = "Pontifex Trust Network"
    organizational_unit = "Planetary Cryptographic Infrastructure"
    country             = "US"
    locality            = "Global"
  }

  validity_period_hours = var.root_ca_validity_hours
  early_renewal_hours   = 8760
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature"
  ]
}

# Export Root Public Certificates to filesystem
resource "local_file" "root_primary_cert" {
  filename        = "${path.root}/.generated/pki/root_ca_primary.crt"
  file_permission = "0644"
  content         = tls_self_signed_cert.root_primary.cert_pem
}

resource "local_file" "root_secondary_cert" {
  filename        = "${path.root}/.generated/pki/root_ca_secondary.crt"
  file_permission = "0644"
  content         = tls_self_signed_cert.root_secondary.cert_pem
}

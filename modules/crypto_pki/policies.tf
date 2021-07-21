# Mutual TLS 1.3 cryptographic policy, cipher negotiation, and SAN authorization matrix.
# Enforces planetary zero-trust connection handshakes and SPIFFE URI identity verification.

locals {
  # Strict TLS 1.3 profile configuration
  tls_profile = {
    min_version = "TLSv1_3"
    max_version = "TLSv1_3"
    cipher_suites = [
      "TLS_AES_256_GCM_SHA384",
      "TLS_CHACHA20_POLY1305_SHA256",
      "TLS_AES_128_GCM_SHA256"
    ]
    ecdh_curves = [
      "X25519",
      "Secp384r1",
      "Secp256r1"
    ]
    alpn_protocols = [
      "h2",
      "grpc",
      "http/1.1"
    ]
    require_client_cert   = true
    verify_cert_chain     = true
    verify_spiffe_san     = true
    handshake_timeout_sec = 5
    session_tickets_mode  = "disabled" # Forward secrecy preservation
  }

  # Peer-to-peer SPIFFE authorization matrix defining allowed mTLS caller handshakes
  spiffe_authz_matrix = {
    "auth-service" = {
      target_spiffe_uri = "spiffe://${var.trust_domain}/ns/identity/sa/auth-engine"
      allowed_caller_uris = [
        "spiffe://${var.trust_domain}/ns/commerce/sa/order-ledger",
        "spiffe://${var.trust_domain}/ns/observability/sa/metric-agent"
      ]
      require_client_sni = true
    }
    "order-processor" = {
      target_spiffe_uri = "spiffe://${var.trust_domain}/ns/commerce/sa/order-ledger"
      allowed_caller_uris = [
        "spiffe://${var.trust_domain}/ns/supply-chain/sa/inventory-node",
        "spiffe://${var.trust_domain}/ns/observability/sa/metric-agent"
      ]
      require_client_sni = true
    }
    "inventory-sync" = {
      target_spiffe_uri = "spiffe://${var.trust_domain}/ns/supply-chain/sa/inventory-node"
      allowed_caller_uris = [
        "spiffe://${var.trust_domain}/ns/commerce/sa/order-ledger",
        "spiffe://${var.trust_domain}/ns/observability/sa/metric-agent"
      ]
      require_client_sni = true
    }
    "telemetry-collector" = {
      target_spiffe_uri = "spiffe://${var.trust_domain}/ns/observability/sa/metric-agent"
      allowed_caller_uris = [
        "spiffe://${var.trust_domain}/ns/identity/sa/auth-engine",
        "spiffe://${var.trust_domain}/ns/commerce/sa/order-ledger",
        "spiffe://${var.trust_domain}/ns/supply-chain/sa/inventory-node"
      ]
      require_client_sni = true
    }
  }

  # Cross-region federation rules: Regulates mTLS trust boundaries across sovereign jurisdictions
  jurisdiction_federation_rules = {
    for reg_key, reg in var.regions : reg_key => {
      jurisdiction          = reg.sovereign_jurisdiction
      trusted_jurisdictions = [reg.sovereign_jurisdiction, "us-fed", "eu-gdpr", "apac-sg"]
      enforce_tls_san_match = true
    }
  }
}

# Compile mTLS policy matrix manifest
resource "local_file" "mtls_policy_manifest" {
  filename        = "${path.root}/.generated/pki/mtls_policy_matrix.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name                   = var.fabric_name
    trust_domain                  = var.trust_domain
    tls_profile                   = local.tls_profile
    spiffe_authorization_matrix   = local.spiffe_authz_matrix
    jurisdiction_federation_rules = local.jurisdiction_federation_rules
  })
}

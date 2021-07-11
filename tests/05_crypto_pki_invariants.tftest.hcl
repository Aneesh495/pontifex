# Cryptographic PKI invariants test verifying root trust anchors, fingerprints, and trust bundles.

run "verify_crypto_pki_invariants" {
  command = apply

  variables {
    fabric_name = "pontifex-pki-test"
    environment = "staging"
  }

  assert {
    condition     = output.security_pki.root_primary_fingerprint != ""
    error_message = "Root primary certificate SHA-256 fingerprint must not be empty."
  }

  assert {
    condition     = output.security_pki.root_secondary_fingerprint != ""
    error_message = "Root secondary certificate SHA-256 fingerprint must not be empty."
  }

  assert {
    condition     = output.security_pki.root_primary_fingerprint != output.security_pki.root_secondary_fingerprint
    error_message = "Primary and secondary root certificates must possess distinct fingerprints."
  }

  assert {
    condition     = output.security_pki.latest_audit_block_hash != ""
    error_message = "Latest audit block hash must be populated."
  }
}

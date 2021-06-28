# Unit test suite for the zero-trust cryptographic PKI subsystem.
# Validates Root CA generation, intermediate paths, and SPIFFE SVID URI federation.

run "verify_crypto_pki_invariants" {
  command = plan

  module {
    source = "./modules/crypto_pki"
  }

  variables {
    fabric_name  = "pontifex-test-pki"
    environment  = "staging"
    trust_domain = "pontifex.internal"
    regions = {
      "us-east-1" = {
        cloud_provider         = "aws"
        sovereign_jurisdiction = "us-fed"
        az_count               = 3
        anycast_enabled        = true
        failover_priority      = 1
        weight                 = 100
        egress_capacity_gbps   = 100
      }
      "eu-central-1" = {
        cloud_provider         = "gcp"
        sovereign_jurisdiction = "eu-gdpr"
        az_count               = 3
        anycast_enabled        = true
        failover_priority      = 2
        weight                 = 90
        egress_capacity_gbps   = 100
      }
    }
    workloads = {
      "auth-service" = {
        namespace         = "identity"
        service_account   = "auth-engine"
        port              = 8443
        protocol          = "grpc"
        canary_percentage = 0
        circuit_breaker = {
          consecutive_5xx  = 3
          max_connections  = 1000
          ejection_seconds = 30
        }
        rate_limit_rps    = 5000
        abac_tier         = "tier-0-critical"
        storage_quota_gb  = 100
        replication_mode  = "active-active-crdt"
      }
    }
  }

  # Assert TLS 1.3 profile enforces strict forward secrecy ciphers
  assert {
    condition     = output.tls_profile.min_version == "TLSv1_3" && output.tls_profile.max_version == "TLSv1_3"
    error_message = "Cryptographic profile must enforce strict TLS 1.3 only."
  }

  assert {
    condition     = contains(output.tls_profile.cipher_suites, "TLS_AES_256_GCM_SHA384")
    error_message = "TLS 1.3 profile must support AES-256-GCM cipher suite."
  }

  # Assert SPIFFE authorization matrix covers auth-service
  assert {
    condition     = output.spiffe_authorization_matrix["auth-service"].target_spiffe_uri == "spiffe://pontifex.internal/ns/identity/sa/auth-engine"
    error_message = "Auth service SPIFFE URI target must match the designated namespace and service account."
  }

  # Assert Revocation endpoints are configured
  assert {
    condition     = output.revocation_endpoints.root_crl_distribution_point == "http://crl.pontifex.internal/root.crl"
    error_message = "CRL distribution point must be anchored to the trust domain."
  }
}

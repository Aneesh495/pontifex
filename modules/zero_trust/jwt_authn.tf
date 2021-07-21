# Envoy JWT Authentication filter chains, OIDC token verification, and claim rules.
# Validates cryptographically signed bearer tokens and injects authenticated claims into headers.

locals {
  # JWT Provider configuration
  jwt_providers = {
    "pontifex-idp" = {
      issuer                 = var.jwt_issuer
      audiences              = ["https://pontifex.internal", "https://api.pontifex.internal"]
      remote_jwks_uri        = "${var.jwt_issuer}/.well-known/jwks.json"
      cache_duration_seconds = 300
      forward                = true
      forward_payload_header = "x-jwt-claims"
      payload_in_metadata    = "jwt_payload"
      clock_skew_seconds     = 30
    }
  }

  # Route-level JWT requirement rules
  jwt_requirement_rules = [
    # Identity and security admin routes require strict JWT authentication
    {
      match = {
        prefix = "/identity"
      }
      requires = {
        provider_name = "pontifex-idp"
        required_claims = [
          {
            key   = "iss"
            value = var.jwt_issuer
          },
          {
            key   = "roles"
            value = "fabric-administrator"
          }
        ]
      }
    },
    # Commerce order processing routes require valid user or service tokens
    {
      match = {
        prefix = "/commerce"
      }
      requires = {
        provider_name = "pontifex-idp"
        required_claims = [
          {
            key   = "iss"
            value = var.jwt_issuer
          }
        ]
      }
    },
    # Health and liveness endpoints bypass JWT (protected by mTLS in compute tier)
    {
      match = {
        path = "/healthz"
      }
      requires = null # Allow mTLS without bearer token
    },
    {
      match = {
        path = "/metrics"
      }
      requires = null # Allow internal metric scraper without bearer token
    }
  ]
}

# Export JWT Authentication Manifest
resource "local_file" "jwt_authn_manifest" {
  filename        = "${path.root}/.generated/security/jwt_authn_filter.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name           = var.fabric_name
    jwt_providers         = local.jwt_providers
    jwt_requirement_rules = local.jwt_requirement_rules
  })
}

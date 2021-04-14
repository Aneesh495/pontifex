# Layer 3/4 default-deny network microsegmentation policies.
# Enforces strict namespace isolation, deterministic port whitelisting, and egress lockdown.

locals {
  # Default-deny microsegmentation policies mapped per namespace
  namespace_security_policies = {
    "identity" = {
      namespace           = "identity"
      default_ingress     = "DENY_ALL"
      default_egress      = "DENY_ALL"
      ingress_whitelists = [
        {
          source_namespace = "commerce"
          source_spiffe_sa = "order-ledger"
          destination_port = 8443
          protocol         = "TCP"
          description      = "Allow order processing engine to verify authentication tokens"
        },
        {
          source_namespace = "observability"
          source_spiffe_sa = "metric-agent"
          destination_port = 8443
          protocol         = "TCP"
          description      = "Allow Prometheus telemetry scraping over mTLS"
        }
      ]
      egress_whitelists = [
        {
          destination_tier = "sovereign-data"
          destination_port = 5432
          protocol         = "TCP"
          description      = "Allow identity ledger to communicate with active-active storage partition"
        },
        {
          destination_tier = "private-compute"
          destination_port = 53
          protocol         = "UDP"
          description      = "Allow internal DNS resolution to local resolver"
        }
      ]
    }
    "commerce" = {
      namespace           = "commerce"
      default_ingress     = "DENY_ALL"
      default_egress      = "DENY_ALL"
      ingress_whitelists = [
        {
          source_namespace = "public-ingress"
          source_spiffe_sa = "edge-proxy"
          destination_port = 8080
          protocol         = "TCP"
          description      = "Allow external Anycast edge proxy to route incoming orders"
        },
        {
          source_namespace = "observability"
          source_spiffe_sa = "metric-agent"
          destination_port = 8080
          protocol         = "TCP"
          description      = "Allow telemetry scraper access"
        }
      ]
      egress_whitelists = [
        {
          destination_namespace = "identity"
          destination_port      = 8443
          protocol              = "TCP"
          description           = "Allow auth token verification calls to identity service"
        },
        {
          destination_namespace = "supply-chain"
          destination_port      = 9090
          protocol              = "TCP"
          description           = "Allow inventory validation calls to inventory service"
        },
        {
          destination_tier = "sovereign-data"
          destination_port = 6379
          protocol         = "TCP"
          description      = "Allow order cache queries to consistent hashing cache ring"
        }
      ]
    }
    "supply-chain" = {
      namespace           = "supply-chain"
      default_ingress     = "DENY_ALL"
      default_egress      = "DENY_ALL"
      ingress_whitelists = [
        {
          source_namespace = "commerce"
          source_spiffe_sa = "order-ledger"
          destination_port = 9090
          protocol         = "TCP"
          description      = "Allow commerce order ledger to query inventory stock"
        }
      ]
      egress_whitelists = [
        {
          destination_tier = "sovereign-data"
          destination_port = 5432
          protocol         = "TCP"
          description      = "Allow inventory persistence to active-active storage partition"
        }
      ]
    }
    "observability" = {
      namespace           = "observability"
      default_ingress     = "DENY_ALL"
      default_egress      = "DENY_ALL"
      ingress_whitelists = [
        {
          source_namespace = "*"
          source_spiffe_sa = "*"
          destination_port = 4317
          protocol         = "TCP"
          description      = "Allow all registered workloads to export OpenTelemetry gRPC traces and metrics"
        }
      ]
      egress_whitelists = [
        {
          destination_tier = "sovereign-data"
          destination_port = 9092
          protocol         = "TCP"
          description      = "Allow telemetry pipeline export to write-ahead log partitions"
        }
      ]
    }
  }
}

# Export Network Microsegmentation Policies
resource "local_file" "network_policies_manifest" {
  filename        = "${path.root}/.generated/security/network_microsegmentation_policies.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name          = var.fabric_name
    total_namespaces     = length(local.namespace_security_policies)
    isolation_mode       = "STRICT_DEFAULT_DENY"
    namespace_policies   = local.namespace_security_policies
  })
}

# Workload SPIFFE SVID (SPIFFE Verifiable Identity Document) leaf certificate synthesizer.
# Generates cryptographic mTLS identities encoded with SPIFFE URI SANs signed by regional intermediate CAs.

locals {
  # Cartesian product mapping every workload to every sovereign cloud region
  workload_instances = {
    for pair in flatten([
      for reg_key, reg in var.regions : [
        for wl_key, wl in var.workloads : {
          instance_key = "${reg_key}--${wl_key}"
          region_key   = reg_key
          workload_key = wl_key
          workload     = wl
          spiffe_uri   = "spiffe://${var.trust_domain}/ns/${wl.namespace}/sa/${wl.service_account}"
          dns_names = [
            "${wl_key}.${wl.namespace}.svc.${reg_key}.${var.trust_domain}",
            "${wl_key}.${wl.namespace}.svc.cluster.local",
            "${wl_key}.mesh.internal"
          ]
        }
      ]
    ]) : pair.instance_key => pair
  }
}

# Workload Private Keys
resource "tls_private_key" "workload_svid" {
  for_each = local.workload_instances

  algorithm   = var.key_algorithm
  ecdsa_curve = var.key_algorithm == "ECDSA" ? var.ecdsa_curve : null
  rsa_bits    = var.key_algorithm == "RSA" ? 2048 : null
}

# Workload Certificate Signing Requests with SPIFFE URI SANs
resource "tls_cert_request" "workload_svid" {
  for_each = local.workload_instances

  private_key_pem = tls_private_key.workload_svid[each.key].private_key_pem

  subject {
    common_name         = "${each.value.workload.service_account}.${each.value.region_key}.${var.trust_domain}"
    organization        = "Pontifex Workload SVID"
    organizational_unit = each.value.workload.namespace
    country             = "US"
    locality            = each.value.region_key
  }

  dns_names = each.value.dns_names
  uris      = [each.value.spiffe_uri]
}

# Sign Workload Leaf SVID Certificates using Sovereign Regional Intermediate CA
resource "tls_locally_signed_cert" "workload_svid" {
  for_each = local.workload_instances

  cert_request_pem   = tls_cert_request.workload_svid[each.key].cert_request_pem
  ca_private_key_pem = tls_private_key.regional_intermediate[each.value.region_key].private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.regional_intermediate[each.value.region_key].cert_pem

  validity_period_hours = var.leaf_svid_validity_hours
  early_renewal_hours   = 72 # Renew 3 days before expiry
  is_ca_certificate     = false

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth"
  ]
}

# Export Workload SVID Certificates
resource "local_file" "workload_svid_certs" {
  for_each = local.workload_instances

  filename        = "${path.root}/.generated/pki/svids/${each.key}.crt"
  file_permission = "0644"
  content         = tls_locally_signed_cert.workload_svid[each.key].cert_pem
}

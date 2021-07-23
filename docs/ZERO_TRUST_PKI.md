# Pontifex Zero-Trust Cryptographic PKI Specification

## Overview

The Pontifex Cryptographic PKI module establishes an automated, zero-trust identity plane across all workloads, control planes, and data plane storage engines. Built directly in HCL using native HashiCorp/OpenTofu TLS providers, it provisions an air-gapped dual-root certificate authority, intermediate regional issuing CAs with constrained path lengths, and short-lived SPIFFE verifiable identity documents (SVIDs).

```
                      +-----------------------------+
                      |   Dual-Root CA (Air-gapped) |
                      |    Ed25519 & ECDSA P-384    |
                      |       Validity: 10 yrs      |
                      +-----------------------------+
                                     |
                                     | Signed with pathlen=1
                                     v
                      +-----------------------------+
                      | Regional Intermediate CAs   |
                      |   us-east-1, eu-west-1, ... |
                      |       Validity: 3 yrs       |
                      +-----------------------------+
                                     |
                                     | Signed with pathlen=0
                                     v
             +-----------------------+-----------------------+
             |                                               |
             v                                               v
+--------------------------+                    +--------------------------+
|  Workload SPIFFE SVID    |                    |  Ingress Gateway SVID    |
|   spiffe://pontifex/     |                    |   spiffe://pontifex/     |
|   ns/mesh/sa/order-svc   |                    |   ns/edge/sa/envoy-gw    |
|   TTL: 24h (ECDSA P-384) |                    |   TTL: 24h (ECDSA P-384) |
+--------------------------+                    +--------------------------+
```

---

## 1. Dual-Root Certificate Authority Architecture

Pontifex generates dual independent root certificate authorities to support both high-performance cryptographic operations and quantum-resistant transition profiles:

1. **Ed25519 Root CA**:
   * Used for ultra-low-latency asymmetric signature verification on high-frequency inter-service RPC paths.
   * Key algorithm: `ED25519`
   * Key usage: `cert_signing`, `crl_signing`
   * Lifetime: 87,600 hours (10 years)
2. **ECDSA P-384 Root CA**:
   * Used for strict regulatory and high-assurance transit boundary encryption.
   * Key algorithm: `ECDSA` with curve `P384`
   * Key usage: `cert_signing`, `crl_signing`
   * Lifetime: 87,600 hours (10 years)

Both roots enforce `is_ca_certificate = true` and include comprehensive distinguished name (DN) attributes:
* Common Name: `pontifex-root-ca-{algorithm}`
* Organization: `Pontifex Planetary Fabric`
* Organizational Unit: `Cryptographic Core Engineering`
* Country: `US`

---

## 2. Regional Intermediate CA Hierarchy

Intermediate CAs are generated per operational region to decouple regional issuance from root CA operational availability.

### Security Constraints

* **Path Length Constraint (`pathlen`)**: Set strictly to `1` on root CA signatures and `0` on intermediate CA signatures. This prevents any regional intermediate CA from delegating CA capabilities to unauthorized workloads.
* **Key Usage**:
  * `cert_signing`
  * `crl_signing`
  * `digital_signature`
* **Validity Period**: 26,280 hours (3 years) with automated renewal windows.

---

## 3. SPIFFE SVID Workload Identity

Every workload in the mesh receives a cryptographically bound X.509 certificate conforming to the SPIFFE standard (Secure Production Identity Framework for Everyone).

### SVID URI Scheme

```
spiffe://{trust_domain}/ns/{namespace}/sa/{service_account}
```

* **Trust Domain**: Configurable per deployment (default `pontifex.internal`).
* **Subject Alternative Name (SAN)**: The SPIFFE URI is encoded in the X.509 Subject Alternative Name URI extension.
* **Workload Validity**: Short-lived certificates with maximum 24-hour lifetime (86,400 seconds) to render stolen credentials useless without complex revocation lists.

---

## 4. Modern TLS Profile Enforcement

All service mesh proxies, endpoints, and database clusters enforce modern cipher suites via declarative HCL configuration:

### Protocol Version

* Minimum TLS Version: `TLSv1.3`
* Deprecated Protocols: `SSLv3`, `TLSv1.0`, `TLSv1.1`, and `TLSv1.2` are blocked at the Envoy listener filter level.

### Approved Cipher Suites

1. `TLS_AES_256_GCM_SHA384` (Default for high-assurance data planes)
2. `TLS_CHACHA20_POLY1305_SHA256` (Optimized for edge CPU architectures lacking AES-NI)
3. `TLS_AES_128_GCM_SHA256` (General workload traffic)

---

## 5. Tamper-Evident SHA-256 Audit Ledger

The Zero-Trust module maintains a cryptographic audit stream in `modules/zero_trust/audit_stream.tf`. Every configuration change, policy mutation, or identity issuance is committed to a hash-chained ledger:

$$H_0 = \text{SHA256}(\text{"GENESIS"} \parallel \text{Timestamp}_0 \parallel \text{Event}_0)$$

$$H_i = \text{SHA256}(H_{i-1} \parallel \text{Timestamp}_i \parallel \text{Event}_i)$$

Any retroactive tampering with historical audit entries causes all subsequent hash references in the chain to fail mathematical verification.

### CLI Ledger Audit

The verification CLI checks the integrity of the audit ledger on disk:

```bash
pontifex-cli audit-chain
```

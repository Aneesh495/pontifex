# Pontifex

[![OpenTofu Tests](https://img.shields.io/badge/OpenTofu-1.9.0-blue.svg)](https://opentofu.org)
[![Go Tests](https://img.shields.io/badge/Go-1.24+-00ADD8.svg)](https://golang.org)
[![Security Level](https://img.shields.io/badge/Security-Zero--Trust%20L7-brightgreen.svg)]()
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-yellow.svg)](LICENSE)

Pontifex is an autonomous, planetary-scale cloud transit fabric, cryptographic zero-trust mesh hypervisor, chaos reactor, and disaster recovery consensus substrate implemented directly in declarative HashiCorp Configuration Language (HCL / OpenTofu).

Designed from first principles to operate across arbitrary multi-cloud and sovereign continental regions, Pontifex bridges deterministic networking, zero-trust cryptographic identity, active-active data plane replication, and automated chaos validation into a single, cohesive infrastructure-as-code repository.

```
                              +---------------------------------------+
                              |         Planetary Transit Fabric      |
                              |       10.0.0.0/8 BGP Mesh Topology    |
                              |        Anycast Virtual IP Ingress     |
                              +---------------------------------------+
                                                  |
                                                  v
                              +---------------------------------------+
                              |      Cryptographic Identity Plane     |
                              |   Dual-Root CA (Ed25519 & ECDSA P-384)|
                              |      SPIFFE SVID Workload Attest      |
                              +---------------------------------------+
                                                  |
                                                  v
                              +---------------------------------------+
                              |         L7 Service Mesh Plane         |
                              |      Envoy Dynamic CDS / RDS Discovery|
                              |     Outlier Detection Circuit Breakers|
                              +---------------------------------------+
                                                  |
                                                  v
                              +---------------------------------------+
                              |        Distributed Data Plane         |
                              |      Multi-Paxos Quorum & CRDT Sync   |
                              |      320-vnode Consistent Hash Ring   |
                              +---------------------------------------+
                                      |                       |
                                      v                       v
               +------------------------------+     +-------------------------------+
               |        Chaos Reactor         |     |   Disaster Recovery Engine    |
               | Trans-oceanic Split-Brain    |     | 6-State Consensus Automaton   |
               | Emergency Rollback Tripwires |     | Monotonic Lamport Fencing     |
               +------------------------------+     +-------------------------------+
```

---

## Architectural Highlights

### 1. Planetary Cloud Transit Fabric (`modules/transit_fabric/`)
* **Deterministic Supernetting**: Automatically carves an RFC 1918 / RFC 6598 supernet across continental regions with zero IPAM conflicts via `cidrsubnet` offset geometry.
* **BGP Route Reflector Mesh**: Eliminates $O(N^2)$ full-mesh scaling bottlenecks with a dual-cluster route reflector topology, MD5 session authentication, and dynamic MED/Local-Pref routing policies.
* **Anycast VIP Ingress**: Anycast `/32` virtual IPs announced concurrently across global edge points of presence with geo-proximity fallback coordinates.
* **Resilient Egress NAT**: High-availability, multi-AZ redundant NAT gateways with automated isolation boundaries.

### 2. Cryptographic Zero-Trust Identity (`modules/crypto_pki/`)
* **Dual-Root Certificate Authorities**: Air-gapped Ed25519 root for ultra-low-latency asymmetric signature verification alongside an ECDSA P-384 root for high-assurance compliance boundaries.
* **Constrained Intermediate Hierarchy**: Regional issuing CAs enforcing X.509 `pathlen:1` on root signatures and `pathlen:0` on intermediate signatures, preventing unauthorized sub-CA delegation.
* **Workload SPIFFE SVIDs**: Automated leaf certificate issuance encoding SPIFFE URIs (`spiffe://pontifex/ns/{namespace}/sa/{workload}`) with short 24-hour validity windows.
* **Strict TLS 1.3 Profile**: Exclusive support for forward-secret cipher suites (`TLS_AES_256_GCM_SHA384`, `TLS_CHACHA20_POLY1305_SHA256`).
* **Tamper-Evident Audit Stream**: Cryptographic SHA-256 chained audit ledger tracking all policy and credential mutations.

### 3. Envoy L7 Service Mesh Control (`modules/service_mesh/`)
* **Dynamic Cluster Discovery (CDS)**: Fully parameterized upstream clusters with sub-second connect timeouts and active health checking.
* **Canary Traffic Steering (RDS)**: Weighted multi-cluster route discovery supporting arbitrary percentage splits (e.g., 90/10 canary) and header overrides.
* **Outlier Detection Circuit Breaking**: Automatic host ejection upon consecutive 5xx error bursts with exponential quarantine backoff.
* **Distributed Token-Bucket Rate Limiting**: Multi-tiered rate limiters enforcing burst capacity and continuous token replenishment.
* **L7 Fault Injection**: Surgical injection of latency delays and abort HTTP status codes for controlled resilience validation.

### 4. Distributed Data Plane Substrate (`modules/data_plane/`)
* **Active-Active CRDT Replication**: State-based conflict-free replicated data types ensuring eventual consistency across multi-region data stores.
* **Multi-Paxos Quorum Invariants**: Odd-numbered node configurations enforcing quorum threshold $Q = \lfloor N/2 \rfloor + 1$ to guarantee safety during partitions.
* **Consistent Hashing Cache Ring**: 320 virtual nodes per physical region mapped across the 64-bit integer space, minimizing cache churn during node scaling.
* **Hierarchical Storage Lifecycle**: Multi-tier lifecycle migration transitioning objects from Hot NVMe to Warm S3, Cold Glacier, and immutable WORM archives.
* **Write-Ahead Log (WAL) Partitions**: Partition trees guaranteeing total log ordering across distributed partitions.

### 5. Automated Chaos Reactor (`modules/chaos_reactor/`)
* **Split-Brain Network Partitions**: Declarative network slicing isolating selected regions or bisecting transatlantic links.
* **Network Degradation Injection**: Synthetic round-trip latency expansion, packet jitter, and deterministic packet drop rates.
* **Zone Evacuation Drills**: Controlled connection draining and traffic diversion to validate zero-downtime zonal failure resilience.
* **Hypothesis Verifiers**: Real-time evaluation against golden signals (error rates, P99 latencies, quorum status).
* **Emergency Rollback Tripwires**: Automatic blast-radius tripwires that immediately restore network topology upon SLA breach.

### 6. Disaster Recovery State Machine (`modules/disaster_recovery/`)
* **6-State Consensus Automaton**: Formal failover lifecycle transitioning from `HEALTHY` to `DEGRADED`, `FAILING_OVER`, `QUORUM_RECONFIGURING`, `PROMOTED`, and `RESTORING`.
* **Monotonic Lamport Fencing**: Fencing tokens incremented upon regional promotion to mathematically preclude split-brain stale writes.
* **Healthchecked DNS Failover**: Weighted global DNS failover records coupled with low TTLs and multi-vantage health probers.
* **Point-In-Time Recovery (PITR)**: Coordinated continuous WAL streaming and hourly storage snapshot manifests.
* **Declarative SLA Auditor**: Compile-time and runtime validation ensuring $\text{RPO} \le 60\text{s}$ and $\text{RTO} \le 300\text{s}$.

### 7. Declarative Policy-as-Code Subsystem (`policies/`)
* **CIDR Invariant Auditing**: Formally validates supernet containment, non-overlap, and minimum host capacities.
* **Cryptographic Profiles**: Enforces minimum 384-bit curves or 256-bit Edwards curves and deprecates legacy RSA/MD5/SHA1.
* **Data Sovereignty Compliance**: Audits data residency and residency restrictions (GDPR EU-only zones, FedRAMP US boundaries).
* **Resilience Topology Invariants**: Enforces minimum 3 availability zones and cross-region replication factors.

---

## Repository Layout

```
.
├── environments/               # Target deployment topology manifests
│   ├── chaos_sandbox/          # Isolated resilience test environment
│   ├── global_fabric/          # Production planetary multi-region deployment
│   └── regional_edge/          # Edge point-of-presence micro-fabric
├── modules/                    # Reusable, composable HCL infrastructure modules
│   ├── chaos_reactor/          # Partition, degradation, evacuation, tripwire logic
│   ├── crypto_pki/             # Dual-root CA, intermediate CA, SPIFFE SVIDs, TLS 1.3
│   ├── data_plane/             # Paxos quorum, CRDT sync, consistent hash ring, WAL
│   ├── disaster_recovery/      # 6-state consensus state machine, Lamport fencing, PITR
│   ├── observability/          # Golden signals alerts, Alertmanager trees, tracing
│   ├── service_mesh/           # Envoy CDS, RDS canary, circuit breaker, rate limit
│   ├── transit_fabric/         # BGP route reflector, anycast VIPs, supernet allocation
│   └── zero_trust/             # RBAC lattice, JWT authn, microsegmentation, audit log
├── policies/                   # Declarative Policy-as-Code invariant verifiers
│   ├── cidr_boundaries.tf      # Supernet containment and non-overlap auditing
│   ├── crypto_compliance.tf    # Key algorithm and TLS profile enforcement
│   ├── data_sovereignty.tf     # GDPR and FedRAMP boundary verification
│   └── resilience_invariants.tf# AZ diversity and quorum constraints
├── tests/                      # Native OpenTofu test suites (*.tftest.hcl)
│   ├── 01_end_to_end_planetary.tftest.hcl
│   ├── 02_edge_failover.tftest.hcl
│   ├── 03_chaos_invalidation.tftest.hcl
│   ├── 04_transit_fabric_topology.tftest.hcl
│   ├── 05_crypto_pki_invariants.tftest.hcl
│   ├── 06_service_mesh_routing.tftest.hcl
│   ├── 07_data_plane_quorum.tftest.hcl
│   ├── 08_chaos_and_observability.tftest.hcl
│   ├── 09_disaster_recovery_sla.tftest.hcl
│   └── 10_policy_as_code.tftest.hcl
├── tools/                      # Systems inspection and testing tooling
│   ├── cli/                    # Standalone Go CLI engine (pontifex-cli)
│   │   ├── main.go             # CLI router and subcommand orchestration
│   │   ├── topology.go         # CIDR tree traversal and BGP adjacency inspector
│   │   ├── cert_verifier.go    # X.509 SPIFFE SAN parser and chain auditor
│   │   ├── chaos_engine.go     # Partition simulator and blast-radius calculator
│   │   └── cli_test.go         # Comprehensive Go unit test suite
│   └── scripts/                # Shell automation and verification scripts
│       ├── verify.sh           # End-to-end 7-step repository validation pipeline
│       └── loc.sh              # Comprehensive lines-of-code metric analyzer
├── docs/                       # Technical specifications and whitepapers
│   ├── ARCHITECTURE.md         # Master architectural whitepaper
│   ├── TRANSIT_SPEC.md         # Planetary transit and BGP specification
│   ├── ZERO_TRUST_PKI.md       # Cryptographic identity and PKI specification
│   ├── SERVICE_MESH.md         # Envoy L7 proxy and routing specification
│   ├── CHAOS_ENGINEERING.md    # Chaos reactor perturbation specification
│   └── RECOVERY_STATE_MACH.md  # Consensus failover and recovery specification
├── Makefile                    # Standardized engineering automation targets
└── README.md                   # System architectural documentation
```

---

## Quickstart & Verification

### Prerequisites
* **OpenTofu**: `>= 1.8.0` (or Terraform `>= 1.6.0`)
* **Go**: `>= 1.22` (for the `pontifex-cli` diagnostic engine)
* **Make**: GNU Make or BSD Make

### 1. Initialize and Validate
Initialize all root configurations and validate module syntax:
```bash
make init
make validate
```

### 2. Run the Native OpenTofu Test Suite
Pontifex ships with 10 comprehensive native test suites in `tests/`:
```bash
make test
```
Sample test output:
```
tests/01_end_to_end_planetary.tftest.hcl... pass
tests/02_edge_failover.tftest.hcl... pass
tests/03_chaos_invalidation.tftest.hcl... pass
tests/04_transit_fabric_topology.tftest.hcl... pass
tests/05_crypto_pki_invariants.tftest.hcl... pass
tests/06_service_mesh_routing.tftest.hcl... pass
tests/07_data_plane_quorum.tftest.hcl... pass
tests/08_chaos_and_observability.tftest.hcl... pass
tests/09_disaster_recovery_sla.tftest.hcl... pass
tests/10_policy_as_code.tftest.hcl... pass
Success! 12 passed, 0 failed.
```

### 3. Build and Test the Pontifex CLI
Compile the diagnostic Go binary and execute its test suite:
```bash
make cli
make test-cli
```

### 4. Run the Master Verification Pipeline
Run the all-in-one verification pipeline to audit formatting, validation, tests, Go builds, and style rules:
```bash
make verify
```

---

## Pontifex CLI Manual

The repository includes a purpose-built Go CLI (`pontifex-cli`) located in `tools/cli/` that inspects live topology, verifies cryptographic chains, and models chaos partitions:

```bash
# Display full planetary topology status
./tools/cli/bin/pontifex-cli inspect

# Render the calculated CIDR tree and check for overlaps
./tools/cli/bin/pontifex-cli cidr-tree

# Audit X.509 certificate chains, SAN SPIFFE URIs, and pathlen constraints
./tools/cli/bin/pontifex-cli verify-pki

# Simulate a trans-oceanic network partition and compute blast radius
./tools/cli/bin/pontifex-cli chaos-sim --split eu-west-1

# Validate the cryptographic integrity of the SHA-256 audit ledger
./tools/cli/bin/pontifex-cli audit-chain
```

---

## Mathematical and System Invariants

### 1. Non-Overlapping Subnet Guarantee
For any pair of regions $(i, j)$ where $i \neq j$:

$$\text{CIDR}_i \cap \text{CIDR}_j = \emptyset$$

Proven through deterministic `cidrsubnet` stride functions over monotonic lexicographic index assignments.

### 2. Paxos Quorum Consensus Safety
For an $N$-node distributed consensus group, any two quorums $Q_1$ and $Q_2$ satisfy the pigeonhole intersection property:

$$|Q_1 \cap Q_2| \ge 1 \quad \text{where} \quad |Q_1| = |Q_2| = \left\lfloor \frac{N}{2} \right\rfloor + 1$$

Ensuring no two disjoint partitions can independently commit conflicting state mutations.

### 3. Consistent Hash Ring Monotonicity
With $K$ virtual nodes per physical node distributed across a hash space of size $M = 2^{64}$:

$$\mathbb{E}[\text{Key Churn on Node Addition}] = \frac{1}{N+1}$$

Providing minimal data migration during horizontal expansion.

---

## License

Pontifex is released under the [Apache 2.0 License](LICENSE).

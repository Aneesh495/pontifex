# Pontifex Chaos Reactor Specification

## Overview

The Pontifex Chaos Reactor is an automated, policy-driven perturbation engine declared in `modules/chaos_reactor/`. It converts resilience engineering from ad-hoc manual drills into reproducible, continuous integration tests. By codifying network partitions, latency degradation, zone evacuations, and steady-state hypothesis verifiers directly into HCL, Pontifex ensures that distributed consensus, routing, and cache invalidation withstand catastrophic real-world failure modes.

```
+-----------------------------------------------------------------------------------+
|                            Pontifex Chaos Reactor                                 |
|                                                                                   |
|  [ Experiment Schedule ]                                                          |
|           |                                                                       |
|           v                                                                       |
|  +------------------------+      Tripwire Triggered       +--------------------+  |
|  | Inject Perturbation    | ============================> | Emergency Rollback |  |
|  | - Trans-oceanic split  |   (Error Rate > 1.0% or       | - Restore BGP mesh |  |
|  | - 150ms link jitter    |    P99 Latency > 800ms)       | - Flush blackholes |  |
|  | - Zone evacuation      |                               | - Rebalance vnodes |  |
|  +------------------------+                               +--------------------+  |
|           |                                                                       |
|           | Continuous Sampling                                                   |
|           v                                                                       |
|  +------------------------+                                                       |
|  | Steady-State Verifier  |                                                       |
|  | - Paxos Quorum Healthy |                                                       |
|  | - Cache Miss Ratio < 5%|                                                       |
|  +------------------------+                                                       |
+-----------------------------------------------------------------------------------+
```

---

## 1. Partition Topologies

The reactor generates deterministic network partition matrices across configured regions in `modules/chaos_reactor/partitions.tf`.

### Mode A: Single-Region Isolation

A selected region is severed from all backbone transit links:
* Ingress and egress BGP peering sessions are torn down.
* Security groups and route tables drop all packets destined for peer transit CIDRs.
* The isolated region must continue servicing local read requests via stale cache reads or gracefully decline writes without corrupting active-active CRDT state.

### Mode B: Trans-Oceanic Split-Brain

A bidirectional partition is injected between North American and European clusters:
* BGP sessions traversing transatlantic undersea cables are severed.
* Multi-paxos quorum logic must detect the split, elect a majority partition leader in the larger quorum cluster, and step down leaders in the minority partition.

---

## 2. Link Degradation and Jitter Injection

Network degradation experiments in `modules/chaos_reactor/degradation.tf` emulate degraded undersea optical lines and congested peering switches:

* **Latency Injection**: Baseline round-trip time artificially inflated by $\Delta T$ (e.g., $+150\text{ms}$).
* **Packet Jitter**: Uniformly or Pareto-distributed delay variance ($\pm 35\text{ms}$).
* **Packet Drop Rate**: Configurable random packet loss (e.g., $1.5\%$ drop rate) targeting L4 TCP retransmit behaviors.

---

## 3. Availability Zone Evacuation Drills

Zonal failures are simulated in `modules/chaos_reactor/eviction.tf` to validate zero-downtime draining:

1. **Phase 1: Ingress Withdrawal**: Weight on target zone Envoy endpoints reduced from $100$ to $0$.
2. **Phase 2: Connection Draining**: Existing long-lived TCP streams permitted up to $60\text{s}$ to terminate gracefully.
3. **Phase 3: Workload Eviction**: Pods and tasks cordoned and scheduled onto surviving availability zones.
4. **Phase 4: Verification**: Zero dropped client transactions during the migration interval.

---

## 4. Steady-State Hypothesis Verification

Every experiment couples perturbations with automated verification criteria in `modules/chaos_reactor/hypotheses.tf`:

| Metric Name | Baseline Threshold | Max Degradation Tolerated | Evaluation Window |
| :--- | :--- | :--- | :--- |
| `mesh_http_5xx_ratio` | $< 0.01\%$ | $< 0.50\%$ | 60 seconds |
| `p99_latency_ms` | $< 120\text{ms}$ | $< 450\text{ms}$ | 60 seconds |
| `paxos_quorum_alive` | `true` | `true` (Hard requirement) | Continuous |
| `cache_ring_coverage` | $100\%$ | $> 95\%$ | 30 seconds |

If any hypothesis metric violates its tolerance threshold, the experiment fails immediately.

---

## 5. Emergency Rollback Tripwires

To guarantee blast-radius containment, the reactor includes hardware and software tripwires:

* **Automated Abort**: If the global error rate exceeds $1.0\%$ for two consecutive 10-second evaluation intervals, the tripwire fires.
* **Idempotent Restoration**: BGP sessions are restored, traffic weights reset to 100%, and blackhole routing entries purged within seconds.
* **Audit Trail**: The tripwire activation event is permanently recorded in the SHA-256 audit ledger.

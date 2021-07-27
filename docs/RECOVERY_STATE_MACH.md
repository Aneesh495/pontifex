# Pontifex Disaster Recovery State Machine Specification

## Overview

The Pontifex Disaster Recovery Subsystem, declared in `modules/disaster_recovery/`, provides a provably safe, consensus-driven failover engine for planetary multi-region topologies. It implements a 6-state deterministic failover automaton, monotonic Lamport fencing tokens, healthchecked DNS routing switchover, continuous write-ahead log (WAL) snapshot coordination, and declarative RPO/RTO SLA verification.

```
                           +-------------------+
                           |      HEALTHY      |
                           +-------------------+
                                     |
                                     | Consecutive Healthcheck Failures >= 3
                                     v
                           +-------------------+
                    +----> |     DEGRADED      | <----+
                    |      +-------------------+      |
                    |                |                |
   Probe Recovered  |                | Quorum Loss    | Promotion Aborted
                    |                v                |
                    |      +-------------------+      |
                    +----- |   FAILING_OVER    | -----+
                           +-------------------+
                                     |
                                     | Leader Majority Vote Confirmed
                                     v
                           +-------------------+
                           |      QUORUM       |
                           |  RECONFIGURING    |
                           +-------------------+
                                     |
                                     | Lamport Fencing Token Incremented
                                     v
                           +-------------------+
                           |     PROMOTED      |
                           +-------------------+
                                     |
                                     | Secondary Cluster Re-sync Complete
                                     v
                           +-------------------+
                           |     RESTORING     |
                           +-------------------+
                                     |
                                     | Full Quorum Re-established
                                     v
                           +-------------------+
                           |      HEALTHY      |
                           +-------------------+
```

---

## 1. 6-State Quorum Consensus State Machine

The failover lifecycle in `modules/disaster_recovery/state_machine.tf` moves through six mutually exclusive states:

1. **HEALTHY**: Primary region processes read/write operations normally. Quorum consensus health probes return HTTP 200 within SLA limits.
2. **DEGRADED**: Transient probe degradation detected (e.g., packet loss or single node failure). Alerting pipelines notified; failover countdown armed.
3. **FAILING_OVER**: Primary region confirmed unreachable by majority of observer nodes. Ingress traffic paused; write locks engaged.
4. **QUORUM_RECONFIGURING**: Surviving nodes form an emergency majority quorum. The unreachable primary is formally partitioned out of the consensus group.
5. **PROMOTED**: Standby secondary region promoted to active primary. A monotonic Lamport fencing token is issued.
6. **RESTORING**: The former primary comes back online, catches up with unapplied WAL entries from the new primary, and rejoins as an in-sync replica before transition back to **HEALTHY**.

---

## 2. Lamport Fencing Tokens

To eliminate split-brain write hazards (where a partitioned former primary continues accepting writes after failover), Pontifex implements monotonically increasing Lamport fencing tokens:

$$\text{Epoch}_{t+1} = \text{Epoch}_t + 1$$

* Every write request to storage nodes, distributed databases, or cache layers must include the current epoch token.
* Storage nodes reject any request presenting a token $\text{Epoch}_{\text{request}} < \text{Epoch}_{\text{node}}$.
* When a standby region is promoted, it increments the global epoch token across all surviving nodes, permanently invalidating any lingering writes from the partitioned former primary.

---

## 3. Geo-Distributed Healthchecked DNS Failover

Ingress failover is coordinated via `modules/disaster_recovery/dns_failover.tf`:

* **Primary Endpoint**: Weighted DNS record pointing to primary Anycast VIP (Weight: 255).
* **Secondary Endpoint**: Standby DNS record pointing to secondary Anycast VIP (Weight: 0 during normal operation, elevated to 255 upon promotion).
* **Health Check Probers**: Geo-distributed probers evaluate the endpoint every 10 seconds from multiple global vantage points.
* **Failover Threshold**: 3 consecutive failures trigger automatic record modification with low DNS TTL (60 seconds) for rapid worldwide propagation.

---

## 4. Continuous WAL Snapshot Coordination

Point-in-time recovery (PITR) is ensured via `modules/disaster_recovery/snapshot_policy.tf`:

* **WAL Archival**: Write-ahead log segments flushed to multi-region object storage every 60 seconds or upon 64MB buffer saturation.
* **Periodic Snapshots**: Base storage snapshots generated hourly with cryptographic SHA-256 manifest verification.
* **Retention Policy**: Hourly snapshots retained for 7 days; daily snapshots retained for 30 days; annual archives retained for 7 years in immutable WORM storage.

---

## 5. Declarative RPO/RTO SLA Verification

Recovery objectives are audited continuously in `modules/disaster_recovery/rpo_rto_sla.tf`:

* **Recovery Point Objective (RPO)**: Maximum acceptable data loss duration. Pontifex target: $\text{RPO} \le 60\text{ seconds}$.
* **Recovery Time Objective (RTO)**: Maximum acceptable downtime before service restoration. Pontifex target: $\text{RTO} \le 300\text{ seconds}$ (5 minutes).

If simulated failover execution tests or snapshot interval audits exceed these bounds, OpenTofu assertion rules trigger immediate build and deployment failures.

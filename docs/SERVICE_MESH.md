# Pontifex Service Mesh Specification

## Overview

The Pontifex Service Mesh architecture configures high-performance Envoy L7 sidecars and edge proxies across all planetary regions. Designed as pure, modular HCL definitions, it manages dynamic cluster discovery (CDS), weighted route discovery (RDS), consecutive-error outlier detection circuit breaking, distributed token-bucket rate limiting, and targeted L7 fault injection.

```
                                  [ Ingress Traffic ]
                                          |
                                          v
                              +-----------------------+
                              |   Envoy Edge Proxy    |
                              |  TLS 1.3 Termination  |
                              |   JWT Claim Authn     |
                              +-----------------------+
                                          |
                     +--------------------+--------------------+
                     |                                         |
     Weight: 90%     v                         Weight: 10%     v
+-------------------------+               +-------------------------+
|   Cluster Stable (v1)   |               |   Cluster Canary (v2)   |
|   Outlier Detection     |               |   Outlier Detection     |
|   Max Ejection: 300s    |               |   Fault Injection Hook  |
+-------------------------+               +-------------------------+
```

---

## 1. Dynamic Envoy Cluster Discovery (CDS)

Envoy clusters are declared in `modules/service_mesh/clusters.tf`. Each cluster represents an upstream group of service instances providing uniform L7 capability.

### Cluster Invariants

* **Connect Timeout**: Set aggressively to `0.25s` (250ms) to rapidly detect partition events.
* **Discovery Type**: `STRICT_DNS` or `LOGICAL_DNS` ensuring automated resolution as dynamic IP addresses cycle.
* **Load Balancing Policy**: `ROUND_ROBIN` or `LEAST_REQUEST` with active health check weighting.
* **HTTP/2 Protocol Options**: Prioritizes multiplexed gRPC and HTTP/2 transport with automated stream window sizing.

---

## 2. Weighted Canary Route Discovery (RDS)

Traffic splitting is governed by `modules/service_mesh/routes.tf`. Routes support arbitrary multi-cluster weighted splits for risk-free zero-downtime rollouts.

### Split Formulation

For a canary deployment with weight $W_{\text{canary}} \in [0, 100]$:

$$W_{\text{stable}} = 100 - W_{\text{canary}}$$

When a request enters the virtual host:
1. Envoy hashes the configured routing key (e.g., session ID, user UUID, or random salt).
2. The request is routed to `canary` if $\text{Hash} \pmod{100} < W_{\text{canary}}$, otherwise to `stable`.
3. Header overrides (e.g., `x-pontifex-stage: canary`) allow deterministic test bypass.

---

## 3. Outlier Detection Circuit Breaking

To protect downstream microservices from cascading systemic collapse, `modules/service_mesh/circuit_breaker.tf` equips every Envoy cluster with passive health checking (outlier detection).

### Parameters

* **Consecutive 5xx Responses**: `3` (eject host after 3 consecutive server errors).
* **Interval**: `10s` (evaluation window).
* **Base Ejection Time**: `30s` (initial quarantine duration).
* **Max Ejection Percent**: `50%` (ensures at least half the cluster remains available to prevent total outage).
* **Enforcing Consec 5xx**: `100%` (strict enforcement).

When an upstream instance breaches error thresholds, it is automatically ejected from the load-balancing pool. The ejection duration doubles for each subsequent ejection up to `300s`.

---

## 4. Distributed Token-Bucket Rate Limiting

Rate limiting is declared in `modules/service_mesh/rate_limiting.tf` using the token-bucket algorithm:

$$\text{Tokens}(t) = \min(C, \text{Tokens}(t - \Delta t) + r \cdot \Delta t)$$

Where:
* $C$ is burst capacity.
* $r$ is fill rate (tokens per second).

### Tiers

1. **Anonymous / Public**: 100 requests per minute with burst up to 20.
2. **Authenticated Workloads**: 5,000 requests per minute with burst up to 500.
3. **Internal Control Plane**: 50,000 requests per minute with burst up to 2,000.

---

## 5. L7 Fault Injection Subsystem

Controlled failure experiments require surgical traffic perturbation. `modules/service_mesh/fault_injection.tf` exposes runtime controls for:

* **Delay Injection**: Configurable percentage of requests delayed by $T_{\text{delay}}$ (e.g., 5% of traffic delayed by 500ms to test upstream timeout resilience).
* **Abort Injection**: Configurable percentage of requests aborted immediately with designated HTTP status code (e.g., 1% aborted with HTTP 503).

# Unit test suite for the active-active data plane subsystem.
# Validates quorum consensus rules, consistent hashing virtual nodes, and WAL partitioning.

run "verify_data_plane_invariants" {
  command = plan

  module {
    source = "./modules/data_plane"
  }

  variables {
    fabric_name                  = "pontifex-test-data"
    environment                  = "staging"
    replication_sync_interval_ms = 100
    cache_virtual_nodes          = 32
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
      "ap-southeast-1" = {
        cloud_provider         = "gcp"
        sovereign_jurisdiction = "apac-sg"
        az_count               = 2
        anycast_enabled        = false
        failover_priority      = 3
        weight                 = 60
        egress_capacity_gbps   = 50
      }
    }
    workloads = {
      "order-processor" = {
        namespace         = "commerce"
        service_account   = "order-ledger"
        port              = 8080
        protocol          = "http2"
        canary_percentage = 10
        circuit_breaker = {
          consecutive_5xx  = 5
          max_connections  = 500
          ejection_seconds = 15
        }
        rate_limit_rps    = 2500
        abac_tier         = "tier-1-business"
        storage_quota_gb  = 500
        replication_mode  = "active-active-quorum"
      }
    }
  }

  # Assert Quorum sizes satisfy majority invariant: R + W > N (For N=3: 2 + 2 > 3)
  assert {
    condition     = output.read_quorum_size == 2 && output.write_quorum_size == 2
    error_message = "Majority quorum size for 3 regions must be 2."
  }

  assert {
    condition     = (output.read_quorum_size + output.write_quorum_size) > 3
    error_message = "Quorum overlap invariant (R + W > N) must hold to prevent stale reads."
  }

  # Assert Consistent Hashing Ring allocates 32 vnodes * 3 regions = 96 vnodes
  assert {
    condition     = output.total_cache_virtual_nodes == 96
    error_message = "Cache ring virtual node calculation does not match expected total."
  }

  # Assert WAL Topics include commerce orders stream
  assert {
    condition     = contains(keys(output.wal_topics), "commerce.orders.stream")
    error_message = "Commerce orders stream must be provisioned in the WAL log topics."
  }
}

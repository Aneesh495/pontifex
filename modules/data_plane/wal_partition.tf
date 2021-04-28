# Write-Ahead Log (WAL) partition trees, distributed append ledgers, and lag monitors.
# Models high-throughput partitioned streams and replication lag alerting boundaries.

locals {
  # Standard WAL stream topic specifications
  wal_topics = {
    "identity.audit.stream" = {
      partitions             = 6
      replication_factor     = min(5, local.total_region_count)
      segment_size_bytes     = var.wal_segment_size_mb * 1024 * 1024
      retention_period_hours = var.wal_retention_hours
      cleanup_policy         = "compact,delete"
      min_insync_replicas    = 3
    }
    "commerce.orders.stream" = {
      partitions             = 12
      replication_factor     = 3
      segment_size_bytes     = var.wal_segment_size_mb * 1024 * 1024
      retention_period_hours = var.wal_retention_hours
      cleanup_policy         = "delete"
      min_insync_replicas    = 2
    }
    "supplychain.inventory.stream" = {
      partitions             = 8
      replication_factor     = 3
      segment_size_bytes     = var.wal_segment_size_mb * 1024 * 1024
      retention_period_hours = var.wal_retention_hours
      cleanup_policy         = "compact"
      min_insync_replicas    = 2
    }
    "telemetry.metrics.stream" = {
      partitions             = 16
      replication_factor     = 2
      segment_size_bytes     = var.wal_segment_size_mb * 2 * 1024 * 1024
      retention_period_hours = 48 # 2 days retention for raw telemetry streams
      cleanup_policy         = "delete"
      min_insync_replicas    = 1
    }
  }

  # Partition leader and follower assignment across sovereign regions
  wal_partition_assignments = {
    for topic_name, topic in local.wal_topics : topic_name => [
      for p_idx in range(topic.partitions) : {
        partition_id       = p_idx
        leader_region      = local.sorted_region_keys[p_idx % local.total_region_count]
        in_sync_replicas   = [
          for r_idx in range(topic.replication_factor) : local.sorted_region_keys[(p_idx + r_idx) % local.total_region_count]
        ]
        max_lag_threshold_ms = 250
      }
    ]
  }

  # Replication lag monitoring criteria
  lag_monitoring_thresholds = {
    warning_threshold_ms  = 100
    critical_threshold_ms = 500
    auto_eject_lagging_replica = true
    ejection_grace_period_sec  = 30
  }
}

# Export WAL Partition Manifest
resource "local_file" "wal_partition_manifest" {
  filename        = "${path.root}/.generated/data/wal_partition_topology.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name               = var.fabric_name
    topics                    = local.wal_topics
    partition_assignments     = local.wal_partition_assignments
    lag_monitoring_thresholds = local.lag_monitoring_thresholds
  })
}

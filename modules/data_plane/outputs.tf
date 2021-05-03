# Active-Active Data Plane module outputs.
# Exposes replication topologies, consistent hashing cache rings, storage policies, and WAL partitions.

output "workload_replication_groups" {
  description = "Active-active CRDT and quorum replication topologies per workload."
  value       = local.workload_replication_groups
}

output "read_quorum_size" {
  description = "Strict read quorum consensus size."
  value       = local.read_quorum_size
}

output "write_quorum_size" {
  description = "Strict write quorum consensus size."
  value       = local.write_quorum_size
}

output "total_cache_virtual_nodes" {
  description = "Total virtual nodes synthesized on the consistent hashing cache ring."
  value       = local.total_virtual_nodes
}

output "regional_cache_clusters" {
  description = "Regional cache cluster shard configurations."
  value       = local.regional_cache_clusters
}

output "storage_lifecycle_tiers" {
  description = "Multi-tier storage lifecycle, retention, and immutability policies."
  value       = local.storage_lifecycle_tiers
}

output "regional_kms_keys" {
  description = "Sovereign Customer Managed Encryption Keys (CMEK) per region."
  value       = local.regional_kms_keys
}

output "wal_topics" {
  description = "Write-Ahead Log stream topics and replication factors."
  value       = local.wal_topics
}

output "wal_partition_assignments" {
  description = "WAL partition leadership and in-sync replica assignments."
  value       = local.wal_partition_assignments
}

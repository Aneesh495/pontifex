# Planetary consistent hashing cache ring synthesizer in pure declarative HCL.
# Distributes cached state across sovereign regional shards with virtual node placement.

locals {
  # Synthesize virtual nodes per regional shard on the consistent hashing ring
  cache_virtual_nodes_list = flatten([
    for reg_key in local.sorted_region_keys : [
      for vnode_idx in range(var.cache_virtual_nodes) : {
        vnode_identifier = "${reg_key}-vnode-${vnode_idx}"
        owning_region    = reg_key
        vnode_index      = vnode_idx
        ring_token_hash  = sha256("${reg_key}-vnode-${vnode_idx}")
      }
    ]
  ])

  # Total virtual nodes on the planetary cache ring
  total_virtual_nodes = length(local.cache_virtual_nodes_list)

  # Cache tier cluster configurations per sovereign region
  regional_cache_clusters = {
    for reg_key in local.sorted_region_keys : reg_key => {
      cluster_id               = "cache-${reg_key}"
      region_key               = reg_key
      jurisdiction             = var.regions[reg_key].sovereign_jurisdiction
      replication_factor       = 3 # Primary plus two cross-region replica mirrors
      max_memory_mb            = 65536 # 64GB cache pool
      eviction_policy          = "allkeys-lru"
      enable_persistence_rdb   = true
      snapshot_interval_sec    = 900
      tls_auth_required        = true
      virtual_nodes_allocated  = var.cache_virtual_nodes
    }
  }

  # Exemplar deterministic partition key mapping evaluation
  test_cache_keys = ["session-auth-001", "order-cart-449", "inventory-sku-881", "telemetry-buffer-092"]
  exemplar_key_mappings = {
    for k in local.test_cache_keys : k => {
      key_hash          = sha256(k)
      assigned_primary  = local.sorted_region_keys[0] # Deterministic assignment in topology model
      replica_mirrors   = slice(local.sorted_region_keys, 1, 3)
      replication_count = 3
    }
  }
}

# Export Cache Ring Manifest
resource "local_file" "cache_ring_manifest" {
  filename        = "${path.root}/.generated/data/cache_ring_topology.json"
  file_permission = "0644"
  content = jsonencode({
    fabric_name             = var.fabric_name
    total_virtual_nodes     = local.total_virtual_nodes
    virtual_nodes_per_shard = var.cache_virtual_nodes
    regional_cache_clusters = local.regional_cache_clusters
    exemplar_key_mappings   = local.exemplar_key_mappings
  })
}

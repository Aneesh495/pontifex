# Data plane quorum and consistent hashing cache ring test.

run "verify_data_plane_quorum_and_hashing" {
  command = plan

  variables {
    fabric_name = "pontifex-data-test"
    environment = "staging"
  }

  assert {
    condition     = output.data_plane_summary.read_quorum_size == 3
    error_message = "Read quorum size for 5 regions must be 3."
  }

  assert {
    condition     = output.data_plane_summary.write_quorum_size == 3
    error_message = "Write quorum size for 5 regions must be 3."
  }

  assert {
    condition     = output.data_plane_summary.cache_virtual_nodes == 320 # 64 vnodes * 5 regions
    error_message = "Total virtual nodes on cache ring must be 320 (64 per region * 5 regions)."
  }

  assert {
    condition     = contains(output.data_plane_summary.wal_topics, "commerce.orders.stream")
    error_message = "WAL topics must contain commerce.orders.stream."
  }
}

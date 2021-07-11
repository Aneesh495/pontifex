# Planetary fabric end-to-end plan verification across all eight sovereign subsystems.

run "verify_end_to_end_planetary_fabric" {
  command = plan

  variables {
    fabric_name          = "pontifex-e2e-planetary"
    environment          = "production"
    global_supernet_cidr = "10.0.0.0/8"
    asn_base             = 64512
  }

  assert {
    condition     = output.fabric_metadata.fabric_name == "pontifex-e2e-planetary"
    error_message = "Fabric name was not propagated to root metadata output."
  }

  assert {
    condition     = output.fabric_metadata.region_count == 5
    error_message = "Default planetary deployment must configure 5 sovereign regions."
  }

  assert {
    condition     = output.fabric_metadata.total_subnets > 0
    error_message = "Subnets must be allocated across all regional tiers."
  }

  assert {
    condition     = output.security_pki.root_primary_fingerprint != ""
    error_message = "Root primary certificate SHA-256 fingerprint must be computed."
  }

  assert {
    condition     = output.service_mesh_summary.total_clusters > 0
    error_message = "Envoy upstream clusters must be synthesized for registered workloads."
  }

  assert {
    condition     = output.data_plane_summary.read_quorum_size == 3 && output.data_plane_summary.write_quorum_size == 3
    error_message = "Majority quorum for 5 regions must be 3 (read=3, write=3)."
  }

  assert {
    condition     = output.disaster_recovery_scorecard.all_workloads_compliant == true
    error_message = "All workloads must pass declarative RPO/RTO SLA evaluations."
  }
}

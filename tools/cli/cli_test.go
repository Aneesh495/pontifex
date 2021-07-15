package main

import (
	"path/filepath"
	"testing"
)

func TestTopologyAndManifests(t *testing.T) {
	manifestDir, err := FindManifestDir()
	if err != nil {
		t.Fatalf("Failed to find manifest directory: %v", err)
	}

	// 1. Test Supernet Manifest
	supernetPath := filepath.Join(manifestDir, "supernet_manifest.json")
	m, err := LoadSupernetManifest(supernetPath)
	if err != nil {
		t.Fatalf("Failed to load supernet manifest: %v", err)
	}

	if m.TotalRegions < 2 {
		t.Errorf("Expected at least 2 regions, got %d", m.TotalRegions)
	}

	if !m.SubnetsAreUnique {
		t.Errorf("Supernet subnets collision detected: subnets are not unique")
	}

	treeOutput := RenderCIDRTree(m)
	if len(treeOutput) == 0 {
		t.Errorf("RenderCIDRTree produced empty output")
	}

	// 2. Test BGP Mesh Topology
	bgpPath := filepath.Join(manifestDir, "bgp_mesh_topology.json")
	bgp, err := LoadBGPMeshTopology(bgpPath)
	if err != nil {
		t.Fatalf("Failed to load BGP topology: %v", err)
	}

	if bgp.TotalPeeringLinks == 0 {
		t.Errorf("Expected positive peering link count, got 0")
	}

	bgpOutput := RenderBGPGraph(bgp)
	if len(bgpOutput) == 0 {
		t.Errorf("RenderBGPGraph produced empty output")
	}
}

func TestAuditLedgerChaining(t *testing.T) {
	manifestDir, err := FindManifestDir()
	if err != nil {
		t.Fatalf("Failed to find manifest directory: %v", err)
	}

	auditPath := filepath.Join(manifestDir, "security", "audit_ledger.json")
	valid, count, err := VerifyAuditLedger(auditPath)
	if err != nil {
		t.Fatalf("Audit ledger validation failed with error: %v", err)
	}

	if !valid {
		t.Errorf("Expected audit ledger to be valid, but got invalid")
	}

	if count < 5 {
		t.Errorf("Expected at least 5 audit blocks in ledger, got %d", count)
	}
}

func TestChaosPartitionSimulation(t *testing.T) {
	manifestDir, err := FindManifestDir()
	if err != nil {
		t.Fatalf("Failed to find manifest directory: %v", err)
	}

	supernetPath := filepath.Join(manifestDir, "supernet_manifest.json")
	m, err := LoadSupernetManifest(supernetPath)
	if err != nil {
		t.Fatalf("Failed to load supernet manifest: %v", err)
	}

	var firstRegion string
	for k := range m.RegionalSupernets {
		firstRegion = k
		break
	}

	res, err := SimulateRegionalPartition(m, firstRegion)
	if err != nil {
		t.Fatalf("Partition simulation failed: %v", err)
	}

	if res.TargetRegion != firstRegion {
		t.Errorf("Target region mismatch: expected %s, got %s", firstRegion, res.TargetRegion)
	}

	if res.SurvivingCount != res.TotalRegions-1 {
		t.Errorf("Surviving count mismatch: expected %d, got %d", res.TotalRegions-1, res.SurvivingCount)
	}

	if !res.QuorumRetained {
		t.Errorf("Expected surviving partition to retain quorum")
	}

	output := RenderChaosResult(res)
	if len(output) == 0 {
		t.Errorf("RenderChaosResult returned empty output")
	}
}

func TestPKICertificateAudit(t *testing.T) {
	manifestDir, err := FindManifestDir()
	if err != nil {
		t.Fatalf("Failed to find manifest directory: %v", err)
	}

	pkiDir := filepath.Join(manifestDir, "pki")
	results, err := AuditPKIDirectory(pkiDir)
	if err != nil {
		t.Fatalf("AuditPKIDirectory failed: %v", err)
	}

	if len(results) == 0 {
		t.Fatalf("No certificates found to audit in %s", pkiDir)
	}

	// Verify all certificates passed chain validation
	for _, r := range results {
		if !r.IsValidChain {
			t.Errorf("Certificate %s failed cryptographic chain validation", r.SubjectCN)
		}
	}

	rendered := RenderCertAudit(results)
	if len(rendered) == 0 {
		t.Errorf("RenderCertAudit returned empty output")
	}
}

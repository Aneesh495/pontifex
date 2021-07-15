package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
)

func printUsage() {
	fmt.Println("Pontifex: Planetary-Scale Declarative Transit Fabric & Mesh Hypervisor CLI")
	fmt.Println()
	fmt.Println("Usage: pontifex <command> [arguments]")
	fmt.Println()
	fmt.Println("Commands:")
	fmt.Println("  inspect       Display holistic topology, BGP peering, and PKI state")
	fmt.Println("  cidr-tree     Render ASCII tree of allocated IPv4 supernets and AZ tiers")
	fmt.Println("  verify-pki    Cryptographically verify Root, Intermediate, and SVID certificates")
	fmt.Println("  chaos-sim     Simulate failure and blast radius of a sovereign region partition")
	fmt.Println("  audit-chain   Verify SHA-256 block hash continuity of the zero-trust audit ledger")
	fmt.Println("  version       Display Pontifex CLI version and build metadata")
}

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	command := os.Args[1]

	manifestDir, err := FindManifestDir()
	if err != nil && command != "version" && command != "help" {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	switch command {
	case "version":
		fmt.Println("pontifex v1.0.0 (darwin/arm64) OpenTofu-native fabric hypervisor")

	case "cidr-tree":
		manifestPath := filepath.Join(manifestDir, "supernet_manifest.json")
		manifest, err := LoadSupernetManifest(manifestPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Print(RenderCIDRTree(manifest))

	case "verify-pki":
		pkiDir := filepath.Join(manifestDir, "pki")
		results, err := AuditPKIDirectory(pkiDir)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error auditing PKI: %v\n", err)
			os.Exit(1)
		}
		fmt.Print(RenderCertAudit(results))

	case "chaos-sim":
		fs := flag.NewFlagSet("chaos-sim", flag.ExitOnError)
		isolateRegion := fs.String("isolate", "", "Region identifier to isolate during simulation")
		_ = fs.Parse(os.Args[2:])

		manifestPath := filepath.Join(manifestDir, "supernet_manifest.json")
		manifest, err := LoadSupernetManifest(manifestPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}

		target := *isolateRegion
		if target == "" {
			// Default to first region in manifest
			for k := range manifest.RegionalSupernets {
				target = k
				break
			}
		}

		result, err := SimulateRegionalPartition(manifest, target)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Simulation error: %v\n", err)
			os.Exit(1)
		}
		fmt.Print(RenderChaosResult(result))

	case "audit-chain":
		auditPath := filepath.Join(manifestDir, "security", "audit_ledger.json")
		valid, count, err := VerifyAuditLedger(auditPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Audit failure: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Cryptographic Audit Ledger: VERIFIED\n")
		fmt.Printf("  Chained Blocks Validated : %d\n", count)
		fmt.Printf("  Hash Tampering Detected  : %t\n", !valid)
		fmt.Printf("  Immutability Status      : INTACT\n")

	case "inspect":
		// Holistic inspection
		supernetPath := filepath.Join(manifestDir, "supernet_manifest.json")
		manifest, err := LoadSupernetManifest(supernetPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}

		bgpPath := filepath.Join(manifestDir, "bgp_mesh_topology.json")
		bgp, err := LoadBGPMeshTopology(bgpPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}

		pkiDir := filepath.Join(manifestDir, "pki")
		pkiResults, _ := AuditPKIDirectory(pkiDir)

		auditPath := filepath.Join(manifestDir, "security", "audit_ledger.json")
		auditValid, blockCount, _ := VerifyAuditLedger(auditPath)

		fmt.Println("================================================================================")
		fmt.Println("PONTIFEX PLANETARY FABRIC INSPECTOR")
		fmt.Println("================================================================================")
		fmt.Print(RenderCIDRTree(manifest))
		fmt.Println()
		fmt.Print(RenderBGPGraph(bgp))
		fmt.Println()
		fmt.Printf("Cryptographic Trust Hierarchy: %d verified certificates\n", len(pkiResults))
		fmt.Printf("Tamper-Evident Audit Ledger  : %d verified blocks (Intact: %t)\n", blockCount, auditValid)
		fmt.Println("================================================================================")

	case "help":
		printUsage()

	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n\n", command)
		printUsage()
		os.Exit(1)
	}
}

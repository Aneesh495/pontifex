package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// SupernetManifest represents the compiled supernet topology.
type SupernetManifest struct {
	FabricName        string                     `json:"fabric_name"`
	Environment       string                     `json:"environment"`
	RootSupernetCIDR  string                     `json:"root_supernet_cidr"`
	TotalRegions      int                        `json:"total_regions"`
	TotalSubnets      int                        `json:"total_subnets"`
	SubnetsAreUnique  bool                       `json:"subnets_are_unique"`
	RegionalSupernets map[string]RegionalSupernet `json:"regional_supernets"`
}

type RegionalSupernet struct {
	RegionKey             string `json:"region_key"`
	CloudProvider         string `json:"cloud_provider"`
	SovereignJurisdiction string `json:"sovereign_jurisdiction"`
	AZCount               int    `json:"az_count"`
	SupernetCIDR          string `json:"supernet_cidr"`
	TransitGatewayIP      string `json:"transit_gateway_ip"`
}

// BGPMeshTopology represents the compiled BGP transit peering topology.
type BGPMeshTopology struct {
	FabricName        string                 `json:"fabric_name"`
	ASNBase           int                    `json:"asn_base"`
	RouteReflectors   []string               `json:"route_reflectors"`
	RegionalASNs      map[string]int         `json:"regional_asns"`
	TotalPeeringLinks int                    `json:"total_peering_links"`
	PeeringLinks      map[string]PeeringLink `json:"peering_links"`
}

type PeeringLink struct {
	LinkID          string `json:"link_id"`
	Source          string `json:"source"`
	Target          string `json:"target"`
	SourceASN       int    `json:"source_asn"`
	TargetASN       int    `json:"target_asn"`
	LinkCIDR        string `json:"link_cidr"`
	RouterSourceIP  string `json:"router_source_ip"`
	RouterTargetIP  string `json:"router_target_ip"`
	IsRouteReflector bool   `json:"is_rr_peering"`
}

// LoadSupernetManifest loads and parses the supernet manifest file.
func LoadSupernetManifest(path string) (*SupernetManifest, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read supernet manifest at %s: %w", path, err)
	}

	var manifest SupernetManifest
	if err := json.Unmarshal(data, &manifest); err != nil {
		return nil, fmt.Errorf("failed to parse supernet manifest JSON: %w", err)
	}

	return &manifest, nil
}

// LoadBGPMeshTopology loads and parses the BGP mesh topology file.
func LoadBGPMeshTopology(path string) (*BGPMeshTopology, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read BGP mesh topology at %s: %w", path, err)
	}

	var topology BGPMeshTopology
	if err := json.Unmarshal(data, &topology); err != nil {
		return nil, fmt.Errorf("failed to parse BGP mesh topology JSON: %w", err)
	}

	return &topology, nil
}

// RenderCIDRTree formats an ASCII visualization of the regional supernet tree.
func RenderCIDRTree(m *SupernetManifest) string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("Planetary Supernet Root: %s (%s, %s)\n", m.RootSupernetCIDR, m.FabricName, m.Environment))
	sb.WriteString(fmt.Sprintf("  Total Sovereign Regions: %d | Total Allocated Subnets: %d (Unique: %t)\n",
		m.TotalRegions, m.TotalSubnets, m.SubnetsAreUnique))
	sb.WriteString("  |\n")

	keys := make([]string, 0, len(m.RegionalSupernets))
	for k := range m.RegionalSupernets {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	for i, k := range keys {
		reg := m.RegionalSupernets[k]
		branch := "+--"
		if i == len(keys)-1 {
			branch = "\\--"
		}
		sb.WriteString(fmt.Sprintf("  %s [%s] %-14s | Provider: %-6s | Jurisdiction: %-8s | Gateway: %s\n",
			branch, reg.SupernetCIDR, reg.RegionKey, reg.CloudProvider, reg.SovereignJurisdiction, reg.TransitGatewayIP))
	}

	return sb.String()
}

// RenderBGPGraph formats an ASCII adjacency representation of the BGP transit peering mesh.
func RenderBGPGraph(b *BGPMeshTopology) string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("Planetary BGP Route Reflector Mesh (ASN Base: %d)\n", b.ASNBase))
	sb.WriteString(fmt.Sprintf("  Route Reflectors: %s\n", strings.Join(b.RouteReflectors, ", ")))
	sb.WriteString(fmt.Sprintf("  Total Point-to-Point Links: %d\n", b.TotalPeeringLinks))
	sb.WriteString("  Inter-Regional Transit Links:\n")

	keys := make([]string, 0, len(b.PeeringLinks))
	for k := range b.PeeringLinks {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	for _, k := range keys {
		link := b.PeeringLinks[k]
		rrTag := ""
		if link.IsRouteReflector {
			rrTag = " [RR Peering]"
		}
		sb.WriteString(fmt.Sprintf("    %-28s : %-16s | %s (ASN %d) <--> %s (ASN %d)%s\n",
			link.LinkID, link.LinkCIDR, link.RouterSourceIP, link.SourceASN, link.RouterTargetIP, link.TargetASN, rrTag))
	}

	return sb.String()
}

// FindManifestDir attempts to locate the .generated directory starting from current path or ancestors.
func FindManifestDir() (string, error) {
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}

	for i := 0; i < 5; i++ {
		candidate := filepath.Join(dir, ".generated")
		if info, err := os.Stat(candidate); err == nil && info.IsDir() {
			return candidate, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}

	return "", fmt.Errorf("could not locate .generated directory; please run 'tofu apply' first")
}

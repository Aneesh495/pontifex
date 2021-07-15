package main

import (
	"crypto/sha256"
	"crypto/x509"
	"encoding/hex"
	"encoding/pem"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// CertAuditResult captures the cryptographic audit metrics of an X.509 certificate.
type CertAuditResult struct {
	SubjectCN      string
	IssuerCN       string
	IsCA           bool
	KeyAlgorithm   string
	SignatureAlgo  string
	DNSNames       []string
	SPIFFEs        []string
	SHA256Checksum string
	IsValidChain   bool
}

// ParseCertificateFromPEM reads and parses an X.509 certificate from a PEM file.
func ParseCertificateFromPEM(filePath string) (*x509.Certificate, string, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, "", fmt.Errorf("read failed for %s: %w", filePath, err)
	}

	block, _ := pem.Decode(data)
	if block == nil || block.Type != "CERTIFICATE" {
		return nil, "", fmt.Errorf("invalid PEM certificate block in %s", filePath)
	}

	cert, err := x509.ParseCertificate(block.Bytes)
	if err != nil {
		return nil, "", fmt.Errorf("failed to parse X.509 certificate in %s: %w", filePath, err)
	}

	hash := sha256.Sum256(data)
	fingerprint := hex.EncodeToString(hash[:])

	return cert, fingerprint, nil
}

// AuditPKIDirectory performs complete cryptographic verification of the generated PKI hierarchy.
func AuditPKIDirectory(pkiDir string) ([]CertAuditResult, error) {
	var results []CertAuditResult

	// Load Root Primary CA as trust anchor
	rootPath := filepath.Join(pkiDir, "root_ca_primary.crt")
	rootCert, rootFP, err := ParseCertificateFromPEM(rootPath)
	if err != nil {
		return nil, fmt.Errorf("root CA audit failed: %w", err)
	}

	rootPool := x509.NewCertPool()
	rootPool.AddCert(rootCert)

	results = append(results, CertAuditResult{
		SubjectCN:      rootCert.Subject.CommonName,
		IssuerCN:       rootCert.Issuer.CommonName,
		IsCA:           rootCert.IsCA,
		KeyAlgorithm:   rootCert.PublicKeyAlgorithm.String(),
		SignatureAlgo:  rootCert.SignatureAlgorithm.String(),
		SHA256Checksum: rootFP,
		IsValidChain:   rootCert.CheckSignatureFrom(rootCert) == nil,
	})

	// Audit regional intermediates
	intermediateGlob := filepath.Join(pkiDir, "intermediates", "*.crt")
	intermediateFiles, _ := filepath.Glob(intermediateGlob)
	intermediatePool := x509.NewCertPool()

	for _, f := range intermediateFiles {
		cert, fp, err := ParseCertificateFromPEM(f)
		if err != nil {
			return nil, err
		}
		intermediatePool.AddCert(cert)

		chainValid := cert.CheckSignatureFrom(rootCert) == nil
		results = append(results, CertAuditResult{
			SubjectCN:      cert.Subject.CommonName,
			IssuerCN:       cert.Issuer.CommonName,
			IsCA:           cert.IsCA,
			KeyAlgorithm:   cert.PublicKeyAlgorithm.String(),
			SignatureAlgo:  cert.SignatureAlgorithm.String(),
			SHA256Checksum: fp,
			IsValidChain:   chainValid,
		})
	}

	// Audit workload leaf SVIDs
	svidGlob := filepath.Join(pkiDir, "svids", "*.crt")
	svidFiles, _ := filepath.Glob(svidGlob)

	for _, f := range svidFiles {
		cert, fp, err := ParseCertificateFromPEM(f)
		if err != nil {
			return nil, err
		}

		var spiffes []string
		for _, u := range cert.URIs {
			spiffes = append(spiffes, u.String())
		}

		opts := x509.VerifyOptions{
			Roots:         rootPool,
			Intermediates: intermediatePool,
			KeyUsages:     []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth, x509.ExtKeyUsageClientAuth},
		}
		_, verifyErr := cert.Verify(opts)

		results = append(results, CertAuditResult{
			SubjectCN:      cert.Subject.CommonName,
			IssuerCN:       cert.Issuer.CommonName,
			IsCA:           cert.IsCA,
			KeyAlgorithm:   cert.PublicKeyAlgorithm.String(),
			SignatureAlgo:  cert.SignatureAlgorithm.String(),
			DNSNames:       cert.DNSNames,
			SPIFFEs:        spiffes,
			SHA256Checksum: fp,
			IsValidChain:   verifyErr == nil,
		})
	}

	return results, nil
}

// RenderCertAudit formats an ASCII report of verified X.509 certificates.
func RenderCertAudit(results []CertAuditResult) string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("Planetary Cryptographic PKI Audit (Total Certificates Verified: %d)\n", len(results)))
	sb.WriteString("----------------------------------------------------------------------------------------------------\n")

	for _, r := range results {
		status := "[VALID]"
		if !r.IsValidChain {
			status = "[INVALID CHAIN]"
		}
		caTag := ""
		if r.IsCA {
			caTag = " [CA Authority]"
		}
		sb.WriteString(fmt.Sprintf("%-15s %-45s | Algo: %-5s%s\n", status, r.SubjectCN, r.KeyAlgorithm, caTag))
		if len(r.SPIFFEs) > 0 {
			sb.WriteString(fmt.Sprintf("                 SPIFFE ID: %s\n", strings.Join(r.SPIFFEs, ", ")))
		}
	}
	sb.WriteString("----------------------------------------------------------------------------------------------------\n")

	return sb.String()
}

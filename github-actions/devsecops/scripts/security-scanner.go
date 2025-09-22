package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// SecurityScanResult represents the consolidated security scan results
type SecurityScanResult struct {
	Timestamp        time.Time              `json:"timestamp"`
	Repository       string                 `json:"repository"`
	CommitSHA        string                 `json:"commit_sha"`
	ScanID           string                 `json:"scan_id"`
	SBOMGenerated    bool                   `json:"sbom_generated"`
	VulnerabilityResults VulnerabilityResults `json:"vulnerability_results"`
	SecurityFindings SecurityFindings       `json:"security_findings"`
	ComplianceStatus ComplianceStatus       `json:"compliance_status"`
	Recommendations  []string               `json:"recommendations"`
}

// VulnerabilityResults contains vulnerability scan results from multiple tools
type VulnerabilityResults struct {
	GrypeResults GrypeScanResult `json:"grype_results"`
	SnykResults  SnykScanResult  `json:"snyk_results"`
	TrivyResults TrivyScanResult `json:"trivy_results"`
	Summary      VulnSummary     `json:"summary"`
}

// GrypeScanResult represents Grype vulnerability scan results
type GrypeScanResult struct {
	Matches []GrypeMatch `json:"matches"`
	Source  GrypeSource  `json:"source"`
}

type GrypeMatch struct {
	Vulnerability GrypeVulnerability `json:"vulnerability"`
	Artifact      GrypeArtifact      `json:"artifact"`
}

type GrypeVulnerability struct {
	ID          string   `json:"id"`
	Severity    string   `json:"severity"`
	Description string   `json:"description"`
	URLs        []string `json:"urls"`
}

type GrypeArtifact struct {
	Name    string `json:"name"`
	Version string `json:"version"`
	Type    string `json:"type"`
}

type GrypeSource struct {
	Type   string `json:"type"`
	Target string `json:"target"`
}

// SnykScanResult represents Snyk scan results
type SnykScanResult struct {
	Vulnerabilities []SnykVulnerability `json:"vulnerabilities"`
	Summary         SnykSummary         `json:"summary"`
}

type SnykVulnerability struct {
	ID       string `json:"id"`
	Title    string `json:"title"`
	Severity string `json:"severity"`
	Package  string `json:"package"`
}

type SnykSummary struct {
	Total    int `json:"total"`
	High     int `json:"high"`
	Medium   int `json:"medium"`
	Low      int `json:"low"`
	Critical int `json:"critical"`
}

// TrivyScanResult represents Trivy scan results
type TrivyScanResult struct {
	Results []TrivyResult `json:"Results"`
}

type TrivyResult struct {
	Target          string                `json:"Target"`
	Vulnerabilities []TrivyVulnerability `json:"Vulnerabilities"`
}

type TrivyVulnerability struct {
	VulnerabilityID string `json:"VulnerabilityID"`
	Severity        string `json:"Severity"`
	Title           string `json:"Title"`
	PkgName         string `json:"PkgName"`
}

// VulnSummary provides aggregated vulnerability statistics
type VulnSummary struct {
	TotalVulnerabilities int `json:"total_vulnerabilities"`
	Critical             int `json:"critical"`
	High                 int `json:"high"`
	Medium               int `json:"medium"`
	Low                  int `json:"low"`
	Info                 int `json:"info"`
	BlockDeployment      bool `json:"block_deployment"`
}

// SecurityFindings contains static analysis and secret scan results
type SecurityFindings struct {
	SecretsFound     bool     `json:"secrets_found"`
	StaticAnalysis   []string `json:"static_analysis_issues"`
	LicenseIssues    []string `json:"license_issues"`
	PolicyViolations []string `json:"policy_violations"`
}

// ComplianceStatus tracks compliance with security frameworks
type ComplianceStatus struct {
	SLSALevel    int  `json:"slsa_level"`
	SSDFCompliant bool `json:"ssdf_compliant"`
	CISCompliant  bool `json:"cis_compliant"`
}

// SecurityScanner orchestrates comprehensive security scanning
type SecurityScanner struct {
	workDir     string
	outputDir   string
	repository  string
	commitSHA   string
	scanID      string
	config      ScannerConfig
}

// ScannerConfig holds configuration for the security scanner
type ScannerConfig struct {
	EnableGrype       bool   `json:"enable_grype"`
	EnableSnyk        bool   `json:"enable_snyk"`
	EnableTrivy       bool   `json:"enable_trivy"`
	EnableSecrets     bool   `json:"enable_secrets"`
	SeverityThreshold string `json:"severity_threshold"`
	BlockOnHigh       bool   `json:"block_on_high"`
	OutputFormat      string `json:"output_format"`
}

// NewSecurityScanner creates a new security scanner instance
func NewSecurityScanner(workDir, outputDir, repository, commitSHA string) *SecurityScanner {
	scanID := fmt.Sprintf("scan-%d", time.Now().Unix())
	
	return &SecurityScanner{
		workDir:    workDir,
		outputDir:  outputDir,
		repository: repository,
		commitSHA:  commitSHA,
		scanID:     scanID,
		config: ScannerConfig{
			EnableGrype:       true,
			EnableSnyk:        true,
			EnableTrivy:       true,
			EnableSecrets:     true,
			SeverityThreshold: "HIGH",
			BlockOnHigh:       true,
			OutputFormat:      "json",
		},
	}
}

// RunComprehensiveScan executes all security scanning tools
func (s *SecurityScanner) RunComprehensiveScan() (*SecurityScanResult, error) {
	log.Printf("Starting comprehensive security scan for %s@%s", s.repository, s.commitSHA)
	
	result := &SecurityScanResult{
		Timestamp:   time.Now(),
		Repository:  s.repository,
		CommitSHA:   s.commitSHA,
		ScanID:      s.scanID,
	}
	
	// Ensure output directory exists
	if err := os.MkdirAll(s.outputDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create output directory: %w", err)
	}
	
	// Step 1: Generate SBOM
	if err := s.generateSBOM(); err != nil {
		log.Printf("SBOM generation failed: %v", err)
		result.SBOMGenerated = false
	} else {
		result.SBOMGenerated = true
		log.Println("✅ SBOM generated successfully")
	}
	
	// Step 2: Run vulnerability scans
	vulnResults, err := s.runVulnerabilityScans()
	if err != nil {
		return nil, fmt.Errorf("vulnerability scanning failed: %w", err)
	}
	result.VulnerabilityResults = *vulnResults
	
	// Step 3: Run security analysis
	secFindings, err := s.runSecurityAnalysis()
	if err != nil {
		return nil, fmt.Errorf("security analysis failed: %w", err)
	}
	result.SecurityFindings = *secFindings
	
	// Step 4: Assess compliance status
	result.ComplianceStatus = s.assessCompliance(result)
	
	// Step 5: Generate recommendations
	result.Recommendations = s.generateRecommendations(result)
	
	// Step 6: Save results
	if err := s.saveResults(result); err != nil {
		return nil, fmt.Errorf("failed to save results: %w", err)
	}
	
	log.Printf("✅ Security scan completed. Scan ID: %s", s.scanID)
	return result, nil
}

// generateSBOM creates Software Bill of Materials using Syft
func (s *SecurityScanner) generateSBOM() error {
	log.Println("Generating SBOM with Syft...")
	
	// Generate SBOM in multiple formats for compatibility
	formats := map[string]string{
		"cyclonedx-json": "sbom-cyclonedx.json",
		"spdx-json":      "sbom-spdx.json",
		"syft-json":      "sbom-syft.json",
	}
	
	for format, filename := range formats {
		outputPath := filepath.Join(s.outputDir, filename)
		cmd := exec.Command("syft", s.workDir, "-o", fmt.Sprintf("%s=%s", format, outputPath))
		
		if output, err := cmd.CombinedOutput(); err != nil {
			return fmt.Errorf("syft %s generation failed: %w\nOutput: %s", format, err, string(output))
		}
		
		log.Printf("Generated SBOM: %s", filename)
	}
	
	return nil
}

// runVulnerabilityScans executes multiple vulnerability scanning tools
func (s *SecurityScanner) runVulnerabilityScans() (*VulnerabilityResults, error) {
	log.Println("Running vulnerability scans...")
	
	results := &VulnerabilityResults{}
	
	// Run Grype scan
	if s.config.EnableGrype {
		grypeResults, err := s.runGrypeScan()
		if err != nil {
			log.Printf("Grype scan failed: %v", err)
		} else {
			results.GrypeResults = *grypeResults
			log.Println("✅ Grype scan completed")
		}
	}
	
	// Run Snyk scan (if token available)
	if s.config.EnableSnyk && os.Getenv("SNYK_TOKEN") != "" {
		snykResults, err := s.runSnykScan()
		if err != nil {
			log.Printf("Snyk scan failed: %v", err)
		} else {
			results.SnykResults = *snykResults
			log.Println("✅ Snyk scan completed")
		}
	}
	
	// Run Trivy scan
	if s.config.EnableTrivy {
		trivyResults, err := s.runTrivyScan()
		if err != nil {
			log.Printf("Trivy scan failed: %v", err)
		} else {
			results.TrivyResults = *trivyResults
			log.Println("✅ Trivy scan completed")
		}
	}
	
	// Generate summary
	results.Summary = s.generateVulnerabilitySummary(results)
	
	return results, nil
}

// runGrypeScan executes Grype vulnerability scanner
func (s *SecurityScanner) runGrypeScan() (*GrypeScanResult, error) {
	sbomPath := filepath.Join(s.outputDir, "sbom-cyclonedx.json")
	outputPath := filepath.Join(s.outputDir, "grype-results.json")
	
	cmd := exec.Command("grype", fmt.Sprintf("sbom:%s", sbomPath), "-o", "json", "--file", outputPath)
	
	if output, err := cmd.CombinedOutput(); err != nil {
		// Grype returns non-zero exit code when vulnerabilities are found
		log.Printf("Grype output: %s", string(output))
	}
	
	// Read and parse results
	data, err := os.ReadFile(outputPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read Grype results: %w", err)
	}
	
	var results GrypeScanResult
	if err := json.Unmarshal(data, &results); err != nil {
		return nil, fmt.Errorf("failed to parse Grype results: %w", err)
	}
	
	return &results, nil
}

// runSnykScan executes Snyk vulnerability scanner
func (s *SecurityScanner) runSnykScan() (*SnykScanResult, error) {
	outputPath := filepath.Join(s.outputDir, "snyk-results.json")
	
	cmd := exec.Command("snyk", "test", "--json", "--file", outputPath)
	cmd.Dir = s.workDir
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		// Snyk returns non-zero exit code when vulnerabilities are found
		log.Printf("Snyk output: %s", string(output))
	}
	
	// Parse Snyk output (it outputs JSON to stdout)
	var results SnykScanResult
	if err := json.Unmarshal(output, &results); err != nil {
		return nil, fmt.Errorf("failed to parse Snyk results: %w", err)
	}
	
	return &results, nil
}

// runTrivyScan executes Trivy vulnerability scanner
func (s *SecurityScanner) runTrivyScan() (*TrivyScanResult, error) {
	outputPath := filepath.Join(s.outputDir, "trivy-results.json")
	
	cmd := exec.Command("trivy", "fs", "--format", "json", "--output", outputPath, s.workDir)
	
	if output, err := cmd.CombinedOutput(); err != nil {
		return nil, fmt.Errorf("trivy scan failed: %w\nOutput: %s", err, string(output))
	}
	
	// Read and parse results
	data, err := os.ReadFile(outputPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read Trivy results: %w", err)
	}
	
	var results TrivyScanResult
	if err := json.Unmarshal(data, &results); err != nil {
		return nil, fmt.Errorf("failed to parse Trivy results: %w", err)
	}
	
	return &results, nil
}

// runSecurityAnalysis performs static analysis and secret scanning
func (s *SecurityScanner) runSecurityAnalysis() (*SecurityFindings, error) {
	log.Println("Running security analysis...")
	
	findings := &SecurityFindings{}
	
	// Run secret scanning with Gitleaks
	if s.config.EnableSecrets {
		secretsFound, err := s.runSecretScan()
		if err != nil {
			log.Printf("Secret scan failed: %v", err)
		} else {
			findings.SecretsFound = secretsFound
			if secretsFound {
				log.Println("⚠️  Secrets detected in repository")
			} else {
				log.Println("✅ No secrets detected")
			}
		}
	}
	
	return findings, nil
}

// runSecretScan executes Gitleaks for secret detection
func (s *SecurityScanner) runSecretScan() (bool, error) {
	outputPath := filepath.Join(s.outputDir, "gitleaks-results.json")
	
	cmd := exec.Command("gitleaks", "detect", "--source", s.workDir, "--report-format", "json", "--report-path", outputPath)
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		// Gitleaks returns non-zero exit code when secrets are found
		if strings.Contains(string(output), "leaks found") {
			return true, nil
		}
		return false, fmt.Errorf("gitleaks scan failed: %w\nOutput: %s", err, string(output))
	}
	
	return false, nil
}

// generateVulnerabilitySummary creates aggregated vulnerability statistics
func (s *SecurityScanner) generateVulnerabilitySummary(results *VulnerabilityResults) VulnSummary {
	summary := VulnSummary{}
	
	// Aggregate Grype results
	for _, match := range results.GrypeResults.Matches {
		summary.TotalVulnerabilities++
		switch strings.ToUpper(match.Vulnerability.Severity) {
		case "CRITICAL":
			summary.Critical++
		case "HIGH":
			summary.High++
		case "MEDIUM":
			summary.Medium++
		case "LOW":
			summary.Low++
		default:
			summary.Info++
		}
	}
	
	// Determine if deployment should be blocked
	if s.config.BlockOnHigh {
		summary.BlockDeployment = summary.Critical > 0 || summary.High > 0
	}
	
	return summary
}

// assessCompliance evaluates compliance with security frameworks
func (s *SecurityScanner) assessCompliance(result *SecurityScanResult) ComplianceStatus {
	status := ComplianceStatus{}
	
	// SLSA Level assessment
	if result.SBOMGenerated {
		status.SLSALevel = 1 // Basic provenance
		if !result.SecurityFindings.SecretsFound && result.VulnerabilityResults.Summary.Critical == 0 {
			status.SLSALevel = 2 // Tamper resistance
		}
	}
	
	// SSDF compliance (basic check)
	status.SSDFCompliant = result.SBOMGenerated && 
		!result.SecurityFindings.SecretsFound && 
		result.VulnerabilityResults.Summary.Critical == 0
	
	// CIS compliance (basic check)
	status.CISCompliant = result.SBOMGenerated && 
		len(result.SecurityFindings.StaticAnalysis) == 0
	
	return status
}

// generateRecommendations provides security improvement recommendations
func (s *SecurityScanner) generateRecommendations(result *SecurityScanResult) []string {
	var recommendations []string
	
	if !result.SBOMGenerated {
		recommendations = append(recommendations, "Enable SBOM generation for supply chain visibility")
	}
	
	if result.SecurityFindings.SecretsFound {
		recommendations = append(recommendations, "Remove detected secrets and implement secret management")
	}
	
	if result.VulnerabilityResults.Summary.Critical > 0 {
		recommendations = append(recommendations, fmt.Sprintf("Address %d critical vulnerabilities immediately", result.VulnerabilityResults.Summary.Critical))
	}
	
	if result.VulnerabilityResults.Summary.High > 0 {
		recommendations = append(recommendations, fmt.Sprintf("Address %d high-severity vulnerabilities", result.VulnerabilityResults.Summary.High))
	}
	
	if result.ComplianceStatus.SLSALevel < 2 {
		recommendations = append(recommendations, "Improve SLSA compliance by implementing signed provenance")
	}
	
	return recommendations
}

// saveResults saves scan results to multiple formats
func (s *SecurityScanner) saveResults(result *SecurityScanResult) error {
	// Save as JSON
	jsonPath := filepath.Join(s.outputDir, "security-scan-results.json")
	jsonData, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal results to JSON: %w", err)
	}
	
	if err := os.WriteFile(jsonPath, jsonData, 0644); err != nil {
		return fmt.Errorf("failed to write JSON results: %w", err)
	}
	
	// Generate summary report
	summaryPath := filepath.Join(s.outputDir, "security-summary.txt")
	summary := s.generateTextSummary(result)
	if err := os.WriteFile(summaryPath, []byte(summary), 0644); err != nil {
		return fmt.Errorf("failed to write summary report: %w", err)
	}
	
	log.Printf("Results saved to %s", s.outputDir)
	return nil
}

// generateTextSummary creates a human-readable summary report
func (s *SecurityScanner) generateTextSummary(result *SecurityScanResult) string {
	var summary strings.Builder
	
	summary.WriteString(fmt.Sprintf("Security Scan Report\n"))
	summary.WriteString(fmt.Sprintf("===================\n\n"))
	summary.WriteString(fmt.Sprintf("Repository: %s\n", result.Repository))
	summary.WriteString(fmt.Sprintf("Commit: %s\n", result.CommitSHA))
	summary.WriteString(fmt.Sprintf("Scan ID: %s\n", result.ScanID))
	summary.WriteString(fmt.Sprintf("Timestamp: %s\n\n", result.Timestamp.Format(time.RFC3339)))
	
	// SBOM Status
	summary.WriteString(fmt.Sprintf("SBOM Generated: %v\n\n", result.SBOMGenerated))
	
	// Vulnerability Summary
	vulnSummary := result.VulnerabilityResults.Summary
	summary.WriteString(fmt.Sprintf("Vulnerability Summary:\n"))
	summary.WriteString(fmt.Sprintf("  Total: %d\n", vulnSummary.TotalVulnerabilities))
	summary.WriteString(fmt.Sprintf("  Critical: %d\n", vulnSummary.Critical))
	summary.WriteString(fmt.Sprintf("  High: %d\n", vulnSummary.High))
	summary.WriteString(fmt.Sprintf("  Medium: %d\n", vulnSummary.Medium))
	summary.WriteString(fmt.Sprintf("  Low: %d\n", vulnSummary.Low))
	summary.WriteString(fmt.Sprintf("  Block Deployment: %v\n\n", vulnSummary.BlockDeployment))
	
	// Security Findings
	summary.WriteString(fmt.Sprintf("Security Findings:\n"))
	summary.WriteString(fmt.Sprintf("  Secrets Found: %v\n", result.SecurityFindings.SecretsFound))
	summary.WriteString(fmt.Sprintf("  Static Analysis Issues: %d\n", len(result.SecurityFindings.StaticAnalysis)))
	summary.WriteString(fmt.Sprintf("  Policy Violations: %d\n\n", len(result.SecurityFindings.PolicyViolations)))
	
	// Compliance Status
	summary.WriteString(fmt.Sprintf("Compliance Status:\n"))
	summary.WriteString(fmt.Sprintf("  SLSA Level: %d\n", result.ComplianceStatus.SLSALevel))
	summary.WriteString(fmt.Sprintf("  SSDF Compliant: %v\n", result.ComplianceStatus.SSDFCompliant))
	summary.WriteString(fmt.Sprintf("  CIS Compliant: %v\n\n", result.ComplianceStatus.CISCompliant))
	
	// Recommendations
	if len(result.Recommendations) > 0 {
		summary.WriteString(fmt.Sprintf("Recommendations:\n"))
		for i, rec := range result.Recommendations {
			summary.WriteString(fmt.Sprintf("  %d. %s\n", i+1, rec))
		}
	}
	
	return summary.String()
}

// main function for CLI usage
func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: security-scanner <work-directory> [output-directory]")
		fmt.Println("Environment variables:")
		fmt.Println("  GITHUB_REPOSITORY - Repository name (owner/repo)")
		fmt.Println("  GITHUB_SHA - Commit SHA")
		fmt.Println("  SNYK_TOKEN - Snyk API token (optional)")
		os.Exit(1)
	}
	
	workDir := os.Args[1]
	outputDir := "./security-results"
	if len(os.Args) > 2 {
		outputDir = os.Args[2]
	}
	
	repository := os.Getenv("GITHUB_REPOSITORY")
	if repository == "" {
		repository = "unknown/repository"
	}
	
	commitSHA := os.Getenv("GITHUB_SHA")
	if commitSHA == "" {
		commitSHA = "unknown"
	}
	
	scanner := NewSecurityScanner(workDir, outputDir, repository, commitSHA)
	
	result, err := scanner.RunComprehensiveScan()
	if err != nil {
		log.Fatalf("Security scan failed: %v", err)
	}
	
	// Print summary to stdout
	fmt.Println(scanner.generateTextSummary(result))
	
	// Exit with error code if deployment should be blocked
	if result.VulnerabilityResults.Summary.BlockDeployment {
		fmt.Println("\n❌ DEPLOYMENT BLOCKED: Critical or high-severity vulnerabilities detected")
		os.Exit(1)
	}
	
	fmt.Println("\n✅ Security scan completed successfully")
}
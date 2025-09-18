# Monitoring Module Variables

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "sbom-security-pipeline"
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = null
  sensitive   = true
}

variable "critical_alert_emails" {
  description = "Email addresses for critical alerts"
  type        = list(string)
  default     = []
}

variable "security_team_emails" {
  description = "Email addresses for security team alerts"
  type        = list(string)
  default     = []
}

variable "vulnerability_threshold" {
  description = "Threshold for vulnerability count alerts"
  type        = number
  default     = 10
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
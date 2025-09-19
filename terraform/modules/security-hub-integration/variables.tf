# Security Hub Integration Variables

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "security_alerts_topic_arn" {
  description = "ARN of the security alerts SNS topic"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
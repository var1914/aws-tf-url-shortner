variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "api_keys" {
  description = "Comma-separated list of valid API keys"
  type        = string
  default     = "demo-key-123,another-key-456"
  sensitive   = true
}
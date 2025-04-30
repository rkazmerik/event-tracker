variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name (e.g., Dev, Prod)"
  type        = string
  default     = "Dev"
}
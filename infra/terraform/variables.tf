variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "nepaltrust"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "ecs_cluster_name" {
  description = "Name of ECS cluster"
  type        = string
  default     = "nepaltrust-cluster"
}

variable "api_container_cpu" {
  description = "CPU units for API container"
  type        = number
  default     = 256
}

variable "api_container_memory" {
  description = "Memory for API container (MB)"
  type        = number
  default     = 512
}

variable "api_task_count" {
  description = "Number of API tasks to run"
  type        = number
  default     = 2
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "api.nepaltrust.com"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for SSL"
  type        = string
  default     = ""
}

variable "pagerduty_endpoint" {
  description = "PagerDuty webhook endpoint for SNS alerts"
  type        = string
  default     = ""
}

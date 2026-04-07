variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "llm-serving-platform"
}

variable "node_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}
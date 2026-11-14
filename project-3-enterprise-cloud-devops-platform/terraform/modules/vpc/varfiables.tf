variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster (used for tagging subnets)"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "AWS Availability Zones for high availability"
}
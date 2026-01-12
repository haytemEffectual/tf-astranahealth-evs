# ----------------------------------
# Variables

variable "aws_region" {
  description = "AWS region for the provider"
  type        = string
  default     = "us-west-2"
}
# variable "vpc1_id" {
#   description = "VPC1 ID where AD service exists"
#   type        = string
# }
# variable "vpc2_id" {
#   description = "VPC2 ID where WorkSpaces will be deployed"
#   type        = string
# }
variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  validation {
    condition     = can(regex("^(dev|prod|staging)$", var.environment))
    error_message = "Environment must be one of: dev, prod, staging."
  }
  type    = string
  default = "dev"
}
variable "evs_vpc_cidr" {
  type = string
}

variable "workspaces_vpc_cidr" {
  type = string
}

variable "on_premises_cidr" {
  description = "On-premises CIDR block"
  type        = string
  default     = "192.168.0.0/16"
}
variable "transit_gateway_id" {
  description = "Transit Gateway ID"
  type        = string
}
variable "domain_name" {
  description = "Active Directory domain name"
  type        = string
  default     = "corp.Astrana.com"
}
variable "domain_short_name" {
  description = "Active Directory short name"
  type        = string
  default     = "CORP"
}

variable "default_ou" {
  description = "Default Organizational Unit for WorkSpaces"
  type        = string
}
variable "ad_dns_ips" {
  description = "DNS IP addresses of AD servers in VPC1"
  type        = list(string)
  default     = ["10.1.10.10", "10.1.10.11"]
}
variable "ad_connector_username" {
  description = "Service account username for AD Connector"
  type        = string
  default     = "svc-adconnector"
}
# Data sources for existing resources
# data "aws_vpc" "vpc1" {
#   id = var.vpc1_id
# }
# data "aws_vpc" "vpc2" {
#   id = var.vpc2_id
# }
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "region-name"
    values = ["us-west-2"]
  }
}

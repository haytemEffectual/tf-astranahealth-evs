# Add Terraform main resources here
# As an Example,below is a VPC Configuration
# 
# below VPC resource if the VPC is needed to be created via TF
resource "aws_vpc" "vpc1" {
  cidr_block           = var.vpc1_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "test-vpc1"
  }
}
resource "aws_vpc" "vpc2" {
  cidr_block           = var.vpc2_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "test-vpc2"
  }
}

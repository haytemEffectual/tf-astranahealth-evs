variable "aws_region" {
  type    = string
  default = "us-west-2"
}

# uncomment and set VPC_CIDR if the VPC is needed to be created via TF
variable "vpc1_cidr" {
  type = string
}

variable "vpc2_cidr" {
  type = string
}
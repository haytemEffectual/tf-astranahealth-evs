provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_west_1"
  region = "us-west-1"
}
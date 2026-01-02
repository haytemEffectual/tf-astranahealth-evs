# Here will be the main tf code for network infrastructure related resources

resource "aws_vpc" "vpc1" {
    region               = project_region
    cidr_block           = var.vpc1_cidr
    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
        Name = "test-vpc1"
    }
}

resource "aws_vpc" "vpc2" {
    region             = project_region
    cidr_block           = var.vpc2_cidr
    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
        Name = "test-vpc2"
    }
}




############################# VPC PEERING CONNECTION ####################

resource "aws_vpc_peering_connection" "vpc1_vpc2" {
  vpc_id      = aws_vpc.vpc1.id
  peer_vpc_id = aws_vpc.vpc2.id
  peer_region = "us-west-2"
  auto_accept = true
  tags = {
    Name        = "VPC1-VPC2-Peering"
    Environment = "Production"
  }
}
# Enable DNS resolution for VPC peering
resource "aws_vpc_peering_connection_options" "vpc1_vpc2" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_vpc2.id
  requester {
    allow_remote_vpc_dns_resolution = true
  }
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}
# Get existing route tables
data "aws_route_tables" "vpc1_private" {
  vpc_id = var.vpc1_id
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}
data "aws_route_tables" "vpc2_private" {
  vpc_id = var.vpc2_id
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}
# Add peering routes to VPC1 route tables
resource "aws_route" "vpc1_to_vpc2" {
  count                     = length(data.aws_route_tables.vpc1_private.ids)
  route_table_id            = data.aws_route_tables.vpc1_private.ids[count.index]
  destination_cidr_block    = var.vpc2_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_vpc2.id
}
# Add peering routes to VPC2 route tables
resource "aws_route" "vpc2_to_vpc1" {
  count                     = length(data.aws_route_tables.vpc2_private.ids)
  route_table_id            = data.aws_route_tables.vpc2_private.ids[count.index]
  destination_cidr_block    = var.vpc1_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_vpc2.id
}
# Add TGW routes for on-premises access
resource "aws_route" "vpc1_to_onprem" {
  count                  = length(data.aws_route_tables.vpc1_private.ids)
  route_table_id         = data.aws_route_tables.vpc1_private.ids[count.index]
  destination_cidr_block = var.on_premises_cidr
  transit_gateway_id     = var.transit_gateway_id
}
resource "aws_route" "vpc2_to_onprem" {
  count                  = length(data.aws_route_tables.vpc2_private.ids)
  route_table_id         = data.aws_route_tables.vpc2_private.ids[count.index]
  destination_cidr_block = var.on_premises_cidr
  transit_gateway_id     = var.transit_gateway_id
}

# Here will be the main tf code for network infrastructure related resources
### TODO: pre-requisite variables should be defined in tfvars file such as:
##    - VPC CIDR blocks Transit 
##    - TGW Gateway ID 
##    - AD details (domain name, DNS IPs, etc)
## 
## This file will be configuring and creating the following resources: 
##  1- VPC1 (EVS) and VPC2 (WorkSpaces)
##  2- VPC Peering between VPC1 (EVS) and VPC2 (WorkSpaces)
##  3- Subnets in both VPCs
##  4- Route tables and associations
##  5- Routes for VPC peering and Transit Gateway
##  6- DHCP Options Set for both VPCs to point to AD DNS IPs
##  6- public subn for NAT Gateway in workspaces VPC
##  7- NAT Gateway in WorkSpaces VPC
##  8- TGW attachments for both VPCs




#####################################################################################
################ CREATING VPCs for the required infrastructure ######################
#####################################################################################
# TODO: update the VPC ids - remove the PVC resources when apply this in prod, PVCs should be pre-existed and has the following tags:
# TODO:  for evs-vpc --> Application="evs" and for workspaces-vpc --> Application="workspaces"
# TODO: you will only need to keep the datasources to read the existing VPC ids 
resource "aws_vpc" "evs" {
  cidr_block           = var.evs_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Application = "evs"
    Name        = "evs-vpc"
  }
}

resource "aws_vpc" "workspaces" {
  cidr_block           = var.workspaces_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Application = "workspaces"
    Name        = "workspaces-vpc"
  }
}

# Data sources to read the VPC IDs created above
data "aws_vpc" "evs" {
  depends_on = [aws_vpc.evs]
  filter {
    name   = "tag:Application"
    values = ["evs"]
  }
}

data "aws_vpc" "workspaces" {
  depends_on = [aws_vpc.workspaces]
  filter {
    name   = "tag:Application"
    values = ["workspaces"]
  }
}


#####################################################################################
############################# CONFIGURING VPC PEERING CONNECTION ####################
#####################################################################################
####  Create VPC peering connection between VPC1 (EVS) and VPC2 (WorkSpaces)
resource "aws_vpc_peering_connection" "evsvpc_workspacesvpc" {
  vpc_id      = data.aws_vpc.evs.id
  peer_vpc_id = data.aws_vpc.workspaces.id
  peer_region = "us-west-2"
  auto_accept = true
  tags = {
    Name        = "Evs-workspaces"
    Environment = var.environment
  }
}
#### Enable DNS resolution for VPC peering
resource "aws_vpc_peering_connection_options" "evsvpc_workspacesvpc" {
  vpc_peering_connection_id = aws_vpc_peering_connection.evsvpc_workspacesvpc.id
  requester {
    allow_remote_vpc_dns_resolution = true
  }
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

#### create subnets in evs-vpc and workspaces-vpc on AZ1 and AZ2
resource "aws_subnet" "evs_vpc_subnets" {
  count             = 2
  vpc_id            = data.aws_vpc.evs.id
  cidr_block        = cidrsubnet(var.evs_vpc_cidr, 4, count.index)
  availability_zone = element(["us-west-2a", "us-west-2b"], count.index)
  tags = {
    Name = "evs-vpc-subnet-${count.index + 1}"
  }
}
resource "aws_subnet" "workspaces_vpc_subnets" {
  count             = 2
  vpc_id            = data.aws_vpc.workspaces.id
  cidr_block        = cidrsubnet(var.workspaces_vpc_cidr, 4, count.index)
  availability_zone = element(["us-west-2a", "us-west-2b"], count.index)
  tags = {
    Name = "workspaces-vpc-subnet-${count.index + 1}"
  }
}

#### ctreate route tables for EVS VPC to route to WorkSpaces VPC
resource "aws_route_table" "evs_vpc_private_rt" {
  vpc_id = data.aws_vpc.evs.id
  tags = {
    Name = "evs-vpc-private-rt"
  }
}

resource "aws_route_table" "workspaces_vpc_private_rt" {
  vpc_id = data.aws_vpc.workspaces.id
  tags = {
    Name = "workspaces-vpc-private-rt"
  }
}


#### Associate subnets with route tables
resource "aws_route_table_association" "evs_vpc_subnets" {
  count          = length(aws_subnet.evs_vpc_subnets)
  subnet_id      = aws_subnet.evs_vpc_subnets[count.index].id
  route_table_id = aws_route_table.evs_vpc_private_rt.id
}

resource "aws_route_table_association" "workspaces_vpc_subnets" {
  count          = length(aws_subnet.workspaces_vpc_subnets)
  subnet_id      = aws_subnet.workspaces_vpc_subnets[count.index].id
  route_table_id = aws_route_table.workspaces_vpc_private_rt.id
}



#### Add peering routes to VPC1 (EVS) route tables
resource "aws_route" "evsvpc_to_workspacesvpc" {
  route_table_id            = aws_route_table.evs_vpc_private_rt.id
  destination_cidr_block    = var.workspaces_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.evsvpc_workspacesvpc.id
}


#### Add peering routes to VPC2 (WorkSpaces) route tables
resource "aws_route" "workspacesvpc_to_evsvpc" {
  route_table_id            = aws_route_table.workspaces_vpc_private_rt.id
  destination_cidr_block    = var.evs_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.evsvpc_workspacesvpc.id
}


#### Add TGW routes for on-premises access
resource "aws_route" "evsvpc_default_route" {
  route_table_id         = aws_route_table.evs_vpc_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
}
resource "aws_route" "workspacesvpc_default_route" {
  route_table_id         = aws_route_table.workspaces_vpc_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
}


#### Create DHCP Options Set for workspaces VPC to point to EVS VPC AD DNS IPs
resource "aws_vpc_dhcp_options" "workspaces_vpc" {
  domain_name         = var.domain_name
  domain_name_servers = var.ad_dns_ips
  tags = {
    Name        = "workspaces-vpc-DHCP"
    Environment = "Production"
  }
}

# Associate DHCP Options with workspaces VPC
resource "aws_vpc_dhcp_options_association" "workspaces_vpc" {
  vpc_id          = data.aws_vpc.workspaces.id
  dhcp_options_id = aws_vpc_dhcp_options.workspaces_vpc.id

}

#####################################################################################
######################### TRANSIT GATEWAY CONFIGURATION ##############################
#####################################################################################
# TODO: update the VPC attachments - remove the attachmet resource in prod, this should be pre-existed 
# you will only need to keeep the datasources re read the existing attachment ids 

# Create TGW VPC attachment for EVS-VPC when enabled
resource "aws_ec2_transit_gateway_vpc_attachment" "evs-vpc" {
  count              = var.create_tgw_attachments ? 1 : 0
  subnet_ids         = aws_subnet.evs_vpc_subnets[*].id
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = data.aws_vpc.evs.id
  tags = {
    Name        = "evs-vpc-TGW-Attachment"
    Environment = var.environment
  }
}

# Create TGW VPC attachment for workspaces-VPC when enabled
resource "aws_ec2_transit_gateway_vpc_attachment" "workspaces" {
  count              = var.create_tgw_attachments ? 1 : 0
  subnet_ids         = aws_subnet.workspaces_vpc_subnets[*].id
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = data.aws_vpc.workspaces.id
  tags = {
    Name        = "workspaces-vpc-TGW-Attachment"
    Environment = var.environment
  }
}




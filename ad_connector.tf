## Here will be the main tf code for AD Connector related resources
## This file will be configuring and creating the following resources: 
## 1- AD Connector in WorkSpaces VPC
## 2- Security Group for AD Connector in WorkSpaces VPC
## 3- Security Group for WorkSpaces instances


###### AD Connector
resource "aws_directory_service_directory" "ad_connector" {
  name        = var.domain_name
  short_name  = var.domain_short_name
  description = "AD Connector for WorkSpaces"
  size        = "Large"
  type        = "ADConnector"
  connect_settings {
    vpc_id            = aws_vpc.workspaces.id
    subnet_ids        = aws_subnet.workspaces_vpc_subnets[*].id
    customer_dns_ips  = var.ad_dns_ips
    customer_username = var.ad_connector_username
  }
  tags = {
    Name        = "WorkSpaces-AD-Connector"
    Environment = var.environment
  }
}

# Wait for AD Connector to be activated
resource "time_sleep" "wait_for_ad_connector" {
  depends_on      = [aws_directory_service_directory.ad_connector]
  create_duration = "420s" # Wait 7 minutes for AD Connector to be ready
}

#######  Security Group for AD Connector in WorkSpaces VPC
resource "aws_security_group" "ad_connector" {
  name_prefix = "workspaces-ad-connector-"
  description = "Security group for AD Connector in WorkSpaces VPC"
  vpc_id      = aws_vpc.workspaces.id
  # Outbound rules for AD communication to EVS VPC
  egress {
    description = "DNS to EVS VPC"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "DNS UDP to EVS VPC"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "Kerberos to EVS VPC"
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "Kerberos UDP to EVS VPC"
    from_port   = 88
    to_port     = 88
    protocol    = "udp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "RPC Endpoint Mapper to EVS VPC"
    from_port   = 135
    to_port     = 135
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "LDAP to EVS VPC"
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "LDAP UDP to EVS VPC"
    from_port   = 389
    to_port     = 389
    protocol    = "udp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "SMB to EVS VPC"
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "Kerberos Change Password to EVS VPC"
    from_port   = 464
    to_port     = 464
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "LDAPS to EVS VPC"
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "Global Catalog to EVS VPC"
    from_port   = 3268
    to_port     = 3269
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "Dynamic RPC to EVS VPC"
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  # HTTPS outbound for WorkSpaces agent registration and management communication
  # NOTE: Requires NAT Gateway or type of connection to the internet in VPC2 to route 0.0.0.0/0 traffic from private subnets to internet
  # TODO: create NAT Gateway in network_infra.tf if not already present  or route through Transit Gateway if it provides internet access
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Restrict to AWS WorkSpaces managed prefix list for better security
  }
  tags = {
    Name        = "WorkSpaces-AD-Connector-SG"
    Environment = "Production"
  }
}

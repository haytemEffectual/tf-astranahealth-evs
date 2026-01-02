# Add Terraform main resources here

# Security Group for AD Connector in VPC2
resource "aws_security_group" "ad_connector" {
  name_prefix = "workspaces-ad-connector-"
  description = "Security group for AD Connector in VPC2"
  vpc_id      = var.vpc2_id
  # Outbound rules for AD communication to VPC1
  egress {
    description = "DNS to VPC1"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "DNS UDP to VPC1"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "Kerberos to VPC1"
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "Kerberos UDP to VPC1"
    from_port   = 88
    to_port     = 88
    protocol    = "udp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "RPC Endpoint Mapper to VPC1"
    from_port   = 135
    to_port     = 135
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "LDAP to VPC1"
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "LDAP UDP to VPC1"
    from_port   = 389
    to_port     = 389
    protocol    = "udp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "SMB to VPC1"
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "Kerberos Change Password to VPC1"
    from_port   = 464
    to_port     = 464
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "LDAPS to VPC1"
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "Global Catalog to VPC1"
    from_port   = 3268
    to_port     = 3269
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  egress {
    description = "Dynamic RPC to VPC1"
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr]
  }
  # Allow HTTPS outbound for WorkSpaces management
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "WorkSpaces-AD-Connector-SG"
    Environment = "Production"
  }
}
# Security Group for WorkSpaces
resource "aws_security_group" "workspaces" {
  name_prefix = "workspaces-"
  description = "Security group for WorkSpaces instances"
  vpc_id      = var.vpc2_id
  # Allow inbound from WorkSpaces service
  ingress {
    description = "WorkSpaces Management"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc2_cidr]
  }
  # Allow outbound to AD Connector
  egress {
    description     = "To AD Connector"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.ad_connector.id]
  }
  # Allow HTTPS outbound
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "WorkSpaces-SG"
    Environment = "Production"
  }
}


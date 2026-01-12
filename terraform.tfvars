# here will be project specific variables
aws_region            = "us-west-2"
environment           = "dev"
on_premises_cidr      = "192.168.0.0/16"
transit_gateway_id    = "tgw-0abcd1234efgh5678"
evs_vpc_cidr          = "10.1.0.0/16"
workspaces_vpc_cidr   = "10.2.0.0/16"
domain_name           = "corp.Astrana.com"
domain_short_name     = "CORP"
default_ou            = "OU=WorkSpaces,DC=corp,DC=example,DC=com"
ad_dns_ips            = ["10.1.10.10", "10.1.10.11"]
ad_connector_username = "svc-adconnector"

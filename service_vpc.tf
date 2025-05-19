locals {
  vpc_name = coalesce(var.vpc_name, "${var.name}-VPC")
  vpc_tags = merge(
    { Project = "${var.name}" },
    var.vpc_tags,
    var.common_tags
  )
  route_detination_cidr = var.vpc_route_destination_cidr

  subnets_cidr            = [for k, v in local.available_zones : cidrsubnet(var.vpc_cidr, local.vpc_subnet_nums, k) if k < pow(2, local.vpc_subnet_nums)]
  ec2_instance_subnet     = local.subnets_cidr[var.ec2_instance_subnet_num]
  ec2_instance_subnet_id  = module.vpc.vpc.subnets[var.ec2_instance_subnet_num].id
  ec2_instance_private_ip = cidrhost(local.ec2_instance_subnet, var.ec2_instance_ip_number)

  security_rule_description = "the security role for EC2 instance"
}

module "vpc" {
  source          = "./modules/vpc"
  name            = local.vpc_name
  available_zones = local.available_zones

  #################################################################
  # AWS VPC
  #################################################################
  create_vpc                           = true
  cidr                                 = var.vpc_cidr
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_network_address_usage_metrics = true
  vpc_tags                             = local.vpc_tags

  #################################################################
  # DHCP option set  
  #################################################################
  enable_dhcp_options               = false
  dhcp_options_domain_name          = "binah.ai"
  dhcp_options_netbios_name_servers = ["169.254.169.253"]
  dhcp_options_tags                 = local.vpc_tags

  #################################################################
  # Internet Gateway
  #################################################################
  create_internet_gateway = true
  internet_gateway_tags   = local.vpc_tags

  #################################################################
  # Subsets
  #################################################################
  subnets_cidr                                       = local.subnets_cidr
  subnet_enable_resource_name_dns_a_record_on_launch = false
  subnet_tags                                        = local.vpc_tags

  #################################################################
  # Route
  #################################################################
  vpc_routes = [
    {
      route_target_name      = "internet_gateway"
      destination_cidr_block = "0.0.0.0/0"
    }
  ]

  #################################################################
  # Network ACLs
  #################################################################
  create_network_acl = true
  acl_tags           = local.vpc_tags
  vpc_acl_rules = [
    #######################################################
    # inbound rules
    #######################################################
    # SSH
    {
      is_inbound  = true
      rule_number = 100
      rule_action = "allow"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    },
    # HTTPs
    {
      is_inbound  = true
      rule_number = 200
      rule_action = "allow"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    },
    # ICMP
    {
      is_inbound  = true
      rule_number = 300
      rule_action = "allow"
      icmp_type   = 0
      icmp_code   = 0
      protocol    = "icmp"
      cidr_block  = "0.0.0.0/0"
    },
    {
      is_inbound  = true
      rule_number = 400
      rule_action = "allow"
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    },
    {
      is_inbound  = true
      rule_number = 500
      rule_action = "allow"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    },
    # others
    {
      is_inbound  = true
      rule_number = 30000
      rule_action = "deny"
      from_port   = 0
      to_port     = 65535
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
    #######################################################
    # outbound rules
    #######################################################
    # HTTPs
    {
      is_inbound  = false
      rule_number = 100
      rule_action = "allow"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    },
    #ICMP
    {
      is_inbound  = false
      rule_number = 200
      rule_action = "allow"
      icmp_type   = 8
      icmp_code   = 0
      protocol    = "icmp"
      cidr_block  = "0.0.0.0/0"
    },
    # SSH
    {
      is_inbound  = false
      rule_number = 300
      rule_action = "allow"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    }
  ]

  #################################################################
  # Security Groups
  #################################################################
  vpc_security_group = {
    EC2 = {
      create                 = true
      revoke_rules_on_delete = false
      tags                   = merge(local.vpc_tags, { UsedFor = "EC2" })
      name                   = "${var.name}-SecurityGroup-EC2"
      rules = [
        # HTTP
        {
          is_inbound  = true
          cidr_ipv4   = local.ec2_instance_subnet
          description = local.security_rule_description
          from_port   = 8000
          to_port     = 8000
          ip_protocol = "tcp"
          tags        = local.vpc_tags
        },
        {
          is_inbound  = true
          cidr_ipv4   = element(local.subnets_cidr, var.ec2_instance_subnet_num + 1)
          description = local.security_rule_description
          from_port   = 8000
          to_port     = 8000
          ip_protocol = "tcp"
          tags        = local.vpc_tags
        },
        # SSH
        {
          is_inbound  = true
          cidr_ipv4   = "0.0.0.0/0"
          description = local.security_rule_description
          from_port   = 22
          to_port     = 22
          ip_protocol = "tcp"
          tags        = local.vpc_tags
        },
        # HTTPs
        {
          is_inbound  = true
          cidr_ipv4   = "0.0.0.0/0"
          description = local.security_rule_description
          from_port   = 443
          to_port     = 443
          ip_protocol = "tcp"
          tags        = local.vpc_tags
        },
        # ICMP
        {
          is_inbound  = true
          cidr_ipv4   = "0.0.0.0/0"
          description = local.security_rule_description
          from_port   = 0
          to_port     = 0
          ip_protocol = "icmp"
          tags        = local.vpc_tags
        },
        # HTTPs
        {
          is_inbound  = false
          cidr_ipv4   = "0.0.0.0/0"
          description = local.security_rule_description
          from_port   = 443
          to_port     = 443
          ip_protocol = "tcp"
          tags        = local.vpc_tags
        },
        # ICMP
        {
          is_inbound  = false
          cidr_ipv4   = "0.0.0.0/0"
          description = local.security_rule_description
          from_port   = 8
          to_port     = 0
          ip_protocol = "icmp"
          tags        = local.vpc_tags
        }
      ]
    }
    ALB = {
      create                 = true
      revoke_rules_on_delete = false
      tags                   = merge(local.vpc_tags, { UsedFor = "ALB" })
      name                   = "${var.name}-SecurityGroup-ALB"
      rules = [
        {
          is_inbound  = true
          cidr_ipv4   = "0.0.0.0/0"
          description = "the security role for ALB instance"
          from_port   = 80
          to_port     = 80
          ip_protocol = "tcp"
          tags        = local.vpc_tags
        },
        {
          is_inbound  = false
          cidr_ipv4   = "0.0.0.0/0"
          description = "the security role for ALB instance"
          # from_port   = 0
          # to_port     = 0
          ip_protocol = "-1"
          tags        = local.vpc_tags
        }
      ]
    }
    APIGateway = {
      create                 = true
      revoke_rules_on_delete = false
      tags                   = merge(local.vpc_tags, { UsedFor = "APIGateway" })
      name                   = "${var.name}-SecurityGroup-APIGateway"
      rules = [
        {
          is_inbound  = true
          cidr_ipv4   = "0.0.0.0/0"
          description = "the security role for APIGateway"
          from_port   = 443
          to_port     = 443
          ip_protocol = "tcp"
          tags        = local.vpc_tags
        },
        {
          is_inbound  = true
          cidr_ipv4   = "0.0.0.0/0"
          description = "the security role for APIGateway"
          from_port   = 80
          to_port     = 80
          ip_protocol = "tcp"
          tags        = local.vpc_tags
        },
        {
          is_inbound  = false
          cidr_ipv4   = "0.0.0.0/0"
          description = "the security role for APIGateway"
          # from_port   = 0
          # to_port     = 0
          ip_protocol = "-1"
          tags        = local.vpc_tags
        }
      ]
    }
  }

  #################################################################
  # VPC Endpoint
  #################################################################
  vpc_endpoints = [
    {
      service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
      tags = merge(
        local.vpc_tags,
        { EndpointTarget = "S3" }
      )
    }
  ]
}

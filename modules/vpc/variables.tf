variable "create_vpc" {
  description = "Controls if VPC should be created (it affects almost all resources)"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  nullable    = false
}

variable "cidr" {
  description = "(Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length` & `ipv4_ipam_pool_id`"
  type        = string
  default     = "172.16.0.0/16"
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_network_address_usage_metrics" {
  description = "Determines whether network address usage metrics are enabled for the VPC"
  type        = bool
  default     = null
}

variable "enable_dhcp_options" {
  description = "Should be true if you want to specify a DHCP options set with a custom domain name, DNS servers, NTP servers, netbios servers, and/or netbios server type"
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Specifies DNS name for DHCP options set (requires enable_dhcp_options set to true)"
  type        = string
  default     = ""
}

variable "dhcp_options_domain_name_servers" {
  description = "Specify a list of DNS server addresses for DHCP options set, default to AWS provided (requires enable_dhcp_options set to true)"
  type        = list(string)
  default     = null
}

variable "dhcp_options_ntp_servers" {
  description = "Specify a list of NTP servers for DHCP options set (requires enable_dhcp_options set to true)"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_name_servers" {
  description = "Specify a list of netbios servers for DHCP options set (requires enable_dhcp_options set to true)"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_node_type" {
  description = "Specify netbios node_type for DHCP options set (requires enable_dhcp_options set to true)"
  type        = string
  default     = ""
}

variable "dhcp_options_tags" {
  description = "Additional tags for the DHCP option set (requires enable_dhcp_options set to true)"
  type        = map(string)
  default     = {}
}

variable "available_zones" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
}

variable "subnets_cidr" {
  description = "A list of CIDRs for every subnet inside the VPC"
  type        = list(string)
  default     = []
}

variable "subnet_enable_resource_name_dns_a_record_on_launch" {
  description = "Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: `false`"
  type        = bool
  default     = false
}

variable "subnet_tags" {
  description = "Additional tags for the public subnets"
  type        = map(string)
  default     = {}
}

variable "route_table_tags" {
  description = "Additional tags for the public route tables"
  type        = map(string)
  default     = {}
}

variable "create_internet_gateway" {
  description = "Controls if an Internet Gateway is created for public subnets and the related routes that connect them"
  type        = bool
  default     = true
}

variable "create_network_acl" {
  description = "Controls if a Network ACL is created for public subnets"
  type        = bool
  default     = false
}

variable "internet_gateway_tags" {
  description = "Additional tags for the internet gateway"
  type        = map(string)
  default     = {}
}

variable "vpc_routes" {
  description = "The route configuration for the VPC"
  type = list(object({
    route_target_name      = string
    destination_cidr_block = optional(string)

    # Only required for the VPC endpoint
    vpc_endpoint_id = optional(string)
  }))
  default = []

  validation {
    condition = anytrue([
      for v in var.vpc_routes : contains(["internet_gateway", "s3"], v.route_target_name)
    ])
    error_message = "The value fo route_target_name does not right"
  }

  validation {
    condition = anytrue([
      for v in var.vpc_routes : (!contains(["s3"], v.route_target_name)) || (contains(["s3"], v.route_target_name) && try(v.vpc_endpoint_id, null) != null)
    ])
    error_message = "The value of vpc_endpoint_id must be specified for the VPC endpoint"
  }
}

variable "acl_tags" {
  description = "Additional tags for the public subnets network ACL"
  type        = map(string)
  default     = {}
}

variable "vpc_acl_rules" {
  description = "Public subnets inbound network ACLs"
  type = list(object({
    is_inbound  = bool
    rule_number = number
    rule_action = string
    from_port   = optional(number)
    to_port     = optional(number)
    # a value of -1 means all protocols
    protocol   = string
    cidr_block = optional(string)
    icmp_type  = optional(number)
    icmp_code  = optional(number)
  }))
  default = []

  validation {
    condition     = anytrue([for v in var.vpc_acl_rules : v.rule_action == "allow" || v.rule_action == "deny"])
    error_message = "The value of ACL rule_action must be either 'allow' or 'deny'"
  }
}

variable "vpc_endpoints" {
  description = "The VPC endpoint configuration for the VPC"
  type = list(object({
    service_name      = string
    service_region    = optional(string)
    vpc_endpoint_type = optional(string, "Gateway")
    auto_accept       = optional(bool, true)
    ip_address_type   = optional(string)
    subnet_configuration = optional(list(object({
      ipv4      = optional(string)
      subnet_id = optional(string)
    })), [])
    subnet_ids = optional(list(string))
    tags       = optional(map(string))
  }))
  default = []
}

variable "vpc_security_group" {
  description = "The security group configuration for the VPC"
  type = map(object({
    create      = bool
    description = optional(string)
    name        = string
    # Instruct Terraform to revoke all of the security groups attached ingress and egree rules before deleting the rule itself
    revoke_rules_on_delete = optional(bool)
    tags                   = optional(map(string))
    rules = optional(list(object({
      is_inbound  = bool
      cidr_ipv4   = optional(string)
      description = optional(string)
      from_port   = optional(number)
      to_port     = optional(number)
      ip_protocol = string
      tags        = optional(map(string), {})
    })), [])
  }))
  default = {}
}

variable "vpc_security_group_rules" {
  description = "Configure rules for the security group"
  type = list(object({
    is_inbound  = bool
    cidr_ipv4   = optional(string)
    description = optional(string)
    from_port   = optional(number)
    to_port     = optional(number)
    ip_protocol = string
    tags        = optional(map(string))
  }))
  default = []
}
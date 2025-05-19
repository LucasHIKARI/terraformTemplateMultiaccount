locals {
  vpc_id = aws_vpc.this[0].id
}

resource "aws_vpc" "this" {
  count      = var.create_vpc ? 1 : 0
  cidr_block = var.cidr

  enable_dns_hostnames                 = var.enable_dns_hostnames
  enable_dns_support                   = var.enable_dns_support
  enable_network_address_usage_metrics = var.enable_network_address_usage_metrics

  tags = merge({
    Name = var.name,
  }, var.vpc_tags)
}

locals {
  create_vpc_dhcp_option = var.create_vpc && var.enable_dhcp_options
}

resource "aws_vpc_dhcp_options" "this" {
  count = local.create_vpc_dhcp_option ? 1 : 0

  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type

  tags = merge(
    { Name = "${var.name}-DHCP" },
    var.dhcp_options_tags,
  )
}

resource "aws_vpc_dhcp_options_association" "this" {
  count           = local.create_vpc_dhcp_option ? 1 : 0
  vpc_id          = local.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

locals {
  num_subnets    = length(var.subnets_cidr)
  create_subnets = var.create_vpc && local.num_subnets > 0
}

resource "aws_internet_gateway" "this" {
  count  = local.create_subnets && var.create_internet_gateway ? 1 : 0
  vpc_id = local.vpc_id
  tags = merge(
    { Name = "${var.name}-InternetGateway" },
    var.internet_gateway_tags
  )
}

resource "aws_subnet" "this" {
  count                                       = local.create_subnets ? local.num_subnets : 0
  vpc_id                                      = local.vpc_id
  availability_zone                           = length(regexall("^[a-z]{2}-", element(var.available_zones, count.index))) > 0 ? element(var.available_zones, count.index) : null
  cidr_block                                  = element(var.subnets_cidr, count.index)
  enable_resource_name_dns_a_record_on_launch = var.subnet_enable_resource_name_dns_a_record_on_launch

  tags = merge(
    { Name = try(format("${var.name}-Subset-%s", count.index)) },
    var.subnet_tags
  )
}

resource "aws_route_table" "this" {
  count  = local.create_subnets ? 1 : 0
  vpc_id = local.vpc_id

  tags = merge(
    var.route_table_tags,
    { Name = "${var.name}-RouteTable" }
  )
}

resource "aws_route_table_association" "this" {
  count          = local.create_subnets ? local.num_subnets : 0
  subnet_id      = element(aws_subnet.this[*].id, count.index)
  route_table_id = aws_route_table.this[0].id
}

locals {
  route_to_internet_gateway = { for k, v in var.vpc_routes : k => v if v.route_target_name == "internet_gateway" }
  route_to_s3               = { for k, v in var.vpc_routes : k => v if v.route_target_name == "s3" }
}

# route to internet gateway
resource "aws_route" "internet" {
  for_each               = local.route_to_internet_gateway
  route_table_id         = aws_route_table.this[0].id
  destination_cidr_block = try(each.value.destination_cidr_block, null)
  gateway_id             = aws_internet_gateway.this[0].id
}

# route to endpoint
resource "aws_route" "s3" {
  for_each               = local.route_to_s3
  route_table_id         = aws_route_table.this[0].id
  destination_cidr_block = try(each.value.destination_cidr_block, null)
  vpc_endpoint_id        = try(each.value.vpc_endpoint_id, null)
}

locals {
  create_network_acl = local.create_subnets && var.create_network_acl
}

resource "aws_network_acl" "this" {
  count      = local.create_network_acl ? 1 : 0
  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.this[*].id

  tags = merge(
    { Name = "${var.name}-NetworkACL" },
    var.acl_tags
  )
}

resource "aws_network_acl_association" "this" {
  count = local.create_network_acl ? local.num_subnets : 0

  subnet_id      = aws_subnet.this[count.index].id
  network_acl_id = aws_network_acl.this[0].id
}

locals {
  acl_inbound_rules  = local.create_subnets && var.create_network_acl ? { for k, s in var.vpc_acl_rules : k => s if s.is_inbound } : {}
  acl_outbound_rules = local.create_subnets && var.create_network_acl ? { for k, s in var.vpc_acl_rules : k => s if !s.is_inbound } : {}
}

resource "aws_network_acl_rule" "inbound" {
  for_each = local.acl_inbound_rules

  network_acl_id = aws_network_acl.this[0].id
  egress         = !each.value.is_inbound
  rule_number    = each.value.rule_number
  rule_action    = each.value.rule_action
  from_port      = try(each.value.from_port, null)
  to_port        = try(each.value.to_port, null)
  protocol       = each.value.protocol
  cidr_block     = try(each.value.cidr_block, null)
  icmp_type      = try(each.value.icmp_type, null)
  icmp_code      = try(each.value.icmp_code, null)
}

resource "aws_network_acl_rule" "outbound" {
  for_each = local.acl_outbound_rules

  network_acl_id = aws_network_acl.this[0].id
  egress         = !each.value.is_inbound
  rule_number    = each.value.rule_number
  rule_action    = each.value.rule_action
  from_port      = try(each.value.from_port, null)
  to_port        = try(each.value.to_port, null)
  protocol       = each.value.protocol
  cidr_block     = try(each.value.cidr_block, null)
  icmp_type      = try(each.value.icmp_type, null)
  icmp_code      = try(each.value.icmp_code, null)
}

locals {
  endpoints = { for k, v in var.vpc_endpoints : k => v if var.create_vpc }
}

resource "aws_vpc_endpoint" "this" {
  for_each = local.endpoints

  vpc_id          = local.vpc_id
  auto_accept     = try(each.value.auto_accept, null)
  ip_address_type = try(each.value.ip_address_type, null)
  route_table_ids = try([aws_route_table.this[0].id], null)
  service_name    = try(each.value.service_name, null)
  service_region  = try(each.value.service_region, null)

  dynamic "subnet_configuration" {
    for_each = { for k, v in each.value.subnet_configuration : k => v }
    content {
      ipv4      = try(each.value.subnet_configuration.ipv4, null)
      subnet_id = try(each.value.subnet_configuration.subnet_id, null)
    }
  }

  subnet_ids = try(each.value.subnet_ids, null)

  tags = merge({
    Name = "${var.name}-Endpoint-${each.key}"
  }, try(each.value.tags, null))
}

locals {
  security_grps = { for k, v in var.vpc_security_group : k => v if var.create_vpc && v.create }
}

resource "aws_security_group" "this" {
  for_each = local.security_grps

  vpc_id                 = local.vpc_id
  description            = try(each.value.description, null)
  name                   = each.value.name
  revoke_rules_on_delete = try(each.value.revoke_rules_on_delete, null)
  tags = merge(
    { Name = "${each.value.name}" },
    each.value.tags
  )
}

locals {
  inbound_rules  = flatten([for k, v in local.security_grps : [for idx, rule in v.rules : merge({ grp_key = k, grp_name = v.name, rule_key = "${v.name}-ingress-${idx}" }, rule) if rule.is_inbound]])
  outbound_rules = flatten([for k, v in local.security_grps : [for idx, rule in v.rules : merge({ grp_key = k, grp_name = v.name, rule_key = "${v.name}-engress-${idx}" }, rule) if !rule.is_inbound]])
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = {
    for v in local.inbound_rules : v.rule_key => v
  }

  security_group_id = aws_security_group.this[each.value.grp_key].id
  ip_protocol       = each.value.ip_protocol
  cidr_ipv4         = try(each.value.cidr_ipv4, null)
  description       = try(each.value.description, null)
  from_port         = try(each.value.from_port, null)
  to_port           = try(each.value.to_port, null)

  tags = merge(
    { Name = "${each.key}" },
    try(each.value.tags, null)
  )
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = {
    for v in local.outbound_rules : v.rule_key => v
  }

  security_group_id = aws_security_group.this[each.value.grp_key].id
  ip_protocol       = each.value.ip_protocol
  cidr_ipv4         = try(each.value.cidr_ipv4, null)
  description       = try(each.value.description, null)
  from_port         = try(each.value.from_port, null)
  to_port           = try(each.value.to_port, null)

  tags = merge(
    { Name = "${each.key}" },
    try(each.value.tags, null)
  )
}
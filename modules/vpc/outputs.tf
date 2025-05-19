output "vpc" {
  description = "The topology information for the vpc"
  value = {
    id         = aws_vpc.this[0].id
    arn        = aws_vpc.this[0].arn
    cidr_block = try(aws_vpc.this[0].cidr_block, null)
    owner_id   = try(aws_vpc.this[0].owner_id, null)
    subnets = [
      for s in aws_subnet.this : {
        id         = try(s.id, null)
        arn        = try(s.arn, null)
        cidr_block = try(s.cidr_block, null)
      }
    ]
    route_table = {
      id      = try(aws_route_table.this[0].id, null)
      arn     = try(aws_route_table.this[0].arn, null)
      subnets = try(aws_route_table_association.this[*].subnet_id, [])
    }
    dhcp = {
      id                  = try(aws_vpc_dhcp_options.this[0].id, null)
      arn                 = try(aws_vpc_dhcp_options.this[0].arn, null)
      domain_name         = try(aws_vpc_dhcp_options.this[0].domain_name, null)
      domain_name_servers = try(aws_vpc_dhcp_options.this[0].domain_name_servers, [])
    }
    internet_gateway = {
      id  = try(aws_internet_gateway.this[0].id, null)
      arn = try(aws_internet_gateway.this[0].arn, null)
    }
    network_acl = {
      id  = try(aws_network_acl.this[0].id, null)
      arn = try(aws_network_acl.this[0].arn, null)
      inbound_rules = [
        for i in aws_network_acl_rule.inbound : {
          id          = try(i.id, null)
          rule_no     = try(i.rule_number, null)
          rule_action = try(i.rule_action, null)
          from_port   = try(i.from_port, null)
          to_port     = try(i.to_port, null)
          protocol    = try(i.protocol, null)
        }
      ]
      outbound_rules = [
        for o in aws_network_acl_rule.outbound : {
          id          = try(o.id, null)
          rule_no     = try(o.rule_number, null)
          rule_action = try(o.rule_action, null)
          from_port   = try(o.from_port, null)
          to_port     = try(o.to_port, null)
          protocol    = try(o.protocol, null)
        }
      ]
    }
    security_group = {
      for k, v in aws_security_group.this : k => {
        id  = try(v.id, null)
        arn = try(v.arn, null)
      }
    }
  }
}
locals {
  create                      = var.create
  create_iam_instance_profile = var.create_iam_instance_profile
  create_eip                  = var.create_eip
  ami                         = var.ami

  iam_role_name = try(coalesce(var.iam_role_name, var.name), "")
}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "assume_role_policy" {
  count = local.create && local.create_iam_instance_profile ? 1 : 0

  statement {
    sid     = var.iam_policy_stament_sid
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "this" {
  count = local.create && local.create_iam_instance_profile ? 1 : 0

  name        = var.iam_role_use_name_prefix ? null : local.iam_role_name
  name_prefix = var.iam_role_use_name_prefix ? "${local.iam_role_name}-" : null
  path        = var.iam_role_path
  description = var.iam_role_description

  assume_role_policy    = data.aws_iam_policy_document.assume_role_policy[0].json
  permissions_boundary  = var.iam_role_permissions_boundary
  force_detach_policies = true

  tags = merge({ "Name" = local.iam_role_name }, var.iam_role_tags)
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = { for k, v in var.iam_role_policies : k => v if var.create && var.create_iam_instance_profile }

  policy_arn = each.value
  role       = aws_iam_role.this[0].name
}

resource "aws_iam_instance_profile" "this" {
  count = var.create && var.create_iam_instance_profile ? 1 : 0

  role = aws_iam_role.this[0].name

  name        = var.iam_role_use_name_prefix ? null : local.iam_role_name
  name_prefix = var.iam_role_use_name_prefix ? "${local.iam_role_name}-" : null
  path        = var.iam_role_path

  tags = merge({ "Name" = local.iam_role_name }, var.iam_role_tags)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "this" {
  count = local.create ? 1 : 0

  ami           = local.ami
  instance_type = var.instance_type
  tags          = merge({ "Name" = var.name }, var.instance_tags)
  user_data     = try(var.user_data, null)

  cpu_options {
    core_count       = var.cpu_core_count
    threads_per_core = var.cpu_threads_per_core
  }

  availability_zone      = var.availability_zone
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  source_dest_check      = var.source_dest_check

  key_name          = var.key_name
  monitoring        = var.monitoring
  get_password_data = var.get_password_data

  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = var.private_ip
  secondary_private_ips       = var.secondary_private_ips
  ipv6_address_count          = var.ipv6_address_count
  ipv6_addresses              = var.ipv6_addresses

  iam_instance_profile = var.instance_iam_profile

  timeouts {
    create = var.timeout_for_create
    read   = var.timeout_for_read
    update = var.timeout_for_update
    delete = var.timeout_for_delete
  }

  maintenance_options {
    auto_recovery = var.auto_recovery
  }

  dynamic "metadata_options" {
    for_each = length(var.metadata_options) > 0 ? [var.metadata_options] : []

    content {
      http_endpoint               = try(metadata_options.value.http_endpoint, "enabled")
      http_protocol_ipv6          = try(metadata_options.value.http_protocol_ipv6, "disabled")
      http_put_response_hop_limit = try(metadata_options.value.http_put_response_hop_limit, 1)
      http_tokens                 = try(metadata_options.value.http_tokens, "required")
      instance_metadata_tags      = try(metadata_options.value.instance_metadata_tags, "disabled")
    }
  }

  lifecycle {
    ignore_changes = [
      ami
    ]
  }
}

resource "aws_eip" "this" {
  count = local.create && local.create_eip ? 1 : 0

  instance = aws_instance.this[0].id

  domain = var.eip_domain

  tags = var.eip_tags
}

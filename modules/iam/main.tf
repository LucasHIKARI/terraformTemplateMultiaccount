
locals {
  policies = { for k, v in var.iam_policy : k => v if v.create }
}

resource "aws_iam_policy" "this" {
  for_each = local.policies

  name        = each.value.name
  name_prefix = each.value.name_prefix
  description = each.value.description
  policy      = each.value.policy
  path        = each.value.path
  tags        = each.value.tags
}


locals {
  roles = { for k, v in var.iam_role : k => v if v.create }
}

resource "aws_iam_role" "this" {
  for_each = local.roles

  assume_role_policy    = each.value.assume_role_policy
  name                  = each.value.name
  name_prefix           = each.value.name_prefix
  description           = each.value.description
  force_detach_policies = each.value.is_force_detach_policies
  max_session_duration  = each.value.max_session_duration_in_second
  path                  = each.value.path
  permissions_boundary  = each.value.permissions_boundary
  tags                  = each.value.tags
}

locals {
  role_policy = {
    for k, v in var.iam_attach_policy_to_role : k => v if v.create
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.role_policy

  role       = aws_iam_role.this[each.value.role_idx].name
  policy_arn = each.value.policy_arn != null ? each.value.policy_arn : aws_iam_policy.this[each.value.policy_idx].arn
}

locals {
  role_service = {
    for k, v in var.specify_role_to_service : k => v if v.create
  }
}

resource "aws_iam_instance_profile" "this" {
  for_each = local.role_service

  name        = each.value.name
  name_prefix = each.value.name_prefix
  path        = each.value.path
  tags        = each.value.tags
  role        = aws_iam_role.this[each.value.role_idx].name
}
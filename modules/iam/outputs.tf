output "role" {
  description = "IAM role information"
  value = [for v in aws_iam_role.this : {
    arn       = try(v.arn, null)
    id        = try(v.id, null)
    name      = try(v.name, null)
    unique_id = try(v.unique_id, null)
  }]
}

output "policy" {
  description = "IAM policy information"
  value = [for v in aws_iam_policy.this : {
    arn              = try(v.arn, null)
    id               = try(v.id, null)
    attachment_count = try(v.attachment_count, null)
    policy_id        = try(v.policy_id, null)
  }]
}

output "service_profile" {
  description = "Instance profile"
  value = [for v in aws_iam_instance_profile.this : {
    name      = try(v.name, null)
    arn       = try(v.arn, null)
    id        = try(v.id, null)
    unique_id = try(v.unique_id, null)
  }]
}

output "policy_role_mapping" {
  description = "Mapping relations between role and policy"
  value = [for v in aws_iam_role_policy_attachment.this : {
    role       = try(v.role, null)
    policy_arn = try(v.policy_arn, null)
  }]
}
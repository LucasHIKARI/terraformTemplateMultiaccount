locals {
  role_name_ec2             = "${var.name}-role-ec2"
  policy_name_ec2           = "${var.name}-policy-ec2"
  auth_path                 = "/${local.lower_name}/"
  iam_instance_profile_name = "${var.name}-EC2AccessS3InstanceProfile"
  role_idx_ec2              = 0
}

module "iam" {
  source = "./modules/iam"
  iam_role = [
    {
      create                   = true
      name                     = local.role_name_ec2
      description              = "The role for the ${var.name} EC2 instance"
      is_force_detach_policies = true
      path                     = local.auth_path
      tags = merge(
        var.common_tags,
        {
          Project = "${var.name}",
          Role    = "EC2"
        }
      )
      assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
    }
  ]

  iam_policy = [
    {
      create      = true
      name        = local.policy_name_ec2
      description = "The policy for the ${var.name} EC2 instance to acess S3"
      path        = local.auth_path
      tags = merge(
        var.common_tags,
        {
          Project = "${var.name}",
          Policy  = "EC2"
        }
      )
      policy = data.aws_iam_policy_document.ec2_access_s3.json
    }
  ]

  iam_attach_policy_to_role = [
    {
      create     = true
      role_idx   = local.role_idx_ec2
      policy_idx = 0
    },
    {
      create     = true
      role_idx   = local.role_idx_ec2
      policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    },
    {
      create     = true
      role_idx   = local.role_idx_ec2
      policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccessV2"
    }
  ]


  specify_role_to_service = [
    {
      create   = true
      name     = local.iam_instance_profile_name
      path     = local.auth_path
      role_idx = 0
      tags = merge(
        var.common_tags,
        {
          Project       = "${var.name}",
          ServicePolicy = "EC2"
        }
      )
    }
  ]

}

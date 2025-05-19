locals {
  waf_tags = merge(
    {
      Project = "${var.name}"
    },
    var.common_tags
  )
}

module "waf" {
  source = "./modules/waf"

  providers = {
    aws = aws.virginia
  }

  web_acl = {
    create = true
    name   = "${local.lower_name}-waf"
    tags   = local.waf_tags
  }

  block_ip_set = {
    create = true
    name   = "${local.lower_name}-waf-block_ip"
    tags   = local.waf_tags
  }
}
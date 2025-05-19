output "waf" {
  description = "The output of WAFv2 WEB ACl"
  value = {
    web_acl = {
      arn                         = try(aws_wafv2_web_acl.main[0].arn, null)
      application_integration_url = try(aws_wafv2_web_acl.main[0].application_integration_url, null)
      capacity                    = try(aws_wafv2_web_acl.main[0].capacity, null)
      id                          = try(aws_wafv2_web_acl.main[0].id, null)
    }
  }
}
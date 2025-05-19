# WAFv2 ACL
resource "aws_wafv2_web_acl" "main" {
  count = var.web_acl.create ? 1 : 0

  name        = var.web_acl.name
  description = "WAF for Binah AI application"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # DDoS対策レベル１（レートリミット）
  rule {
    name     = "RateLimit"
    priority = 1

    action {
      block {}
    }
    # Point 4. 利用回数の制御
    statement {
      rate_based_statement {
        limit              = 3000 # 1IPあたり1リクエスト/5分
        aggregate_key_type = "IP" # IPアドレスごとにリクエストを集計
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # SQL注入防御
  rule {
    name     = "SQLInjectionRule"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    # log
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLInjectionMetric"
      sampled_requests_enabled   = true
    }
  }

  # 一般的なWebアプリケーション脆弱性対策
  rule {
    name     = "CommonRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleMetric"
      sampled_requests_enabled   = true
    }
  }



  # Botアクセス対策
  rule {
    name     = "BadBotRule"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BadBotMetric"
      sampled_requests_enabled   = true
    }
  }

  # IP アドレス制限
  rule {
    name     = "BlockKnownBadIP"
    priority = 5

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.bad_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockKnownBadIPMetric"
      sampled_requests_enabled   = true
    }
  }


  # Web ACL級 log
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "BinahWAFMetric"
    sampled_requests_enabled   = true
  }

  tags = var.web_acl.tags
}

# IPアドレスのブラックリスト
resource "aws_wafv2_ip_set" "bad_ips" {
  name               = var.block_ip_set.name
  description        = "Known malicious IP addresses"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"

  addresses = var.block_ip_set.addresses

  tags = var.block_ip_set.tags
}
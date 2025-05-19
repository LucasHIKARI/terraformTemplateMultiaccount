locals {
  create = var.cloudfront_distribution.create
}

resource "aws_cloudfront_origin_access_control" "this" {
  count = local.create && var.cloudfront_oac.create ? 1 : 0

  name                              = var.cloudfront_oac.name
  description                       = var.cloudfront_oac.description
  origin_access_control_origin_type = var.cloudfront_oac.origin_type
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


resource "aws_cloudfront_vpc_origin" "this" {
  count = local.create && var.cloudfront_vpc_origin.create ? 1 : 0

  dynamic "vpc_origin_endpoint_config" {
    for_each = var.cloudfront_vpc_origin.endpoints
    iterator = endpoint

    content {
      name                   = endpoint.value.name
      arn                    = endpoint.value.arn
      http_port              = endpoint.value.http_port
      https_port             = endpoint.value.https_port
      origin_protocol_policy = endpoint.value.protocol_policy

      dynamic "origin_ssl_protocols" {
        for_each = endpoint.value.ssl
        iterator = ssl

        content {
          items    = ssl.value.items
          quantity = ssl.value.quantity
        }
      }
    }
  }
}

resource "aws_cloudfront_monitoring_subscription" "this" {
  count = local.create && var.cloudfront_monitor.create ? 1 : 0

  distribution_id = aws_cloudfront_distribution.this[0].id

  monitoring_subscription {
    realtime_metrics_subscription_config {
      realtime_metrics_subscription_status = var.cloudfront_monitor.enable_relatime_metrics ? "Enabled" : "Disabled"
    }
  }
}

locals {
  request_policy = local.create ? { for k, v in var.cloudfront_request_policy : k => v } : {}
}

resource "aws_cloudfront_origin_request_policy" "this" {
  for_each = local.request_policy

  name    = each.value.unique_name
  comment = each.value.description
  cookies_config {
    cookie_behavior = each.value.cookies_config.behavior
    dynamic "cookies" {
      for_each = toset(length(each.value.cookies_config.items) > 0 ? ["placeholder"] : [])
      content {
        items = each.value.cookies_config.items
      }
    }
  }
  headers_config {
    header_behavior = each.value.headers_config.behavior
    dynamic "headers" {
      for_each = toset(length(each.value.headers_config.items) > 0 ? ["placeholder"] : [])
      content {
        items = each.value.headers_config.items
      }
    }
  }
  query_strings_config {
    query_string_behavior = each.value.query_strings_config.behavior
    dynamic "query_strings" {
      for_each = toset(length(each.value.query_strings_config.items) > 0 ? ["placeholder"] : [])
      content {
        items = each.value.query_strings_config.items
      }
    }
  }
}

locals {
  response_policy = local.create ? { for k, v in var.cloudfront_response_policy : k => v } : {}
}

resource "aws_cloudfront_response_headers_policy" "this" {
  for_each = local.response_policy

  name    = each.value.unique_name
  comment = each.value.description
  # cors_config {
  #   access_control_allow_credentials = false
  #   access_control_allow_headers {
  #     items = []
  #   }
  #   access_control_allow_methods {
  #     items = []
  #   }
  #   access_control_allow_origins {
  #     items = []
  #   }
  #   origin_override = false
  # }
  dynamic "custom_headers_config" {
    for_each = tolist(length(each.value.custom_headers_config) > 0 ? [each.value.custom_headers_config] : [])
    content {
      dynamic "items" {
        for_each = custom_headers_config.value
        content {
          header   = items.value.header
          override = items.value.override
          value    = items.value.value
        }
      }
    }
  }
  dynamic "remove_headers_config" {
    for_each = tolist(length(each.value.remove_headers) > 0 ? [each.value.remove_headers] : [])
    content {
      dynamic "items" {
        for_each = remove_headers_config.value
        content {
          header = items.value
        }
      }
    }
  }
  server_timing_headers_config {
    enabled       = each.value.server_timing_headers_config.enable
    sampling_rate = each.value.server_timing_headers_config.samping_rate
  }
  security_headers_config {
    dynamic "content_security_policy" {
      for_each = each.value.security_headers_config.content_security_policy
      content {
        content_security_policy = content_security_policy.value
        override                = each.value.security_headers_config.is_override_content_security_policy
      }
    }
    content_type_options {
      override = each.value.security_headers_config.is_override_content_type_options
    }
    frame_options {
      frame_option = each.value.security_headers_config.is_deny_frame_options ? "DENY" : "SAMEORIGIN"
      override     = each.value.security_headers_config.is_override_frame_options
    }
    referrer_policy {
      referrer_policy = each.value.security_headers_config.referrer_policy
      override        = each.value.security_headers_config.is_override_referrer_policy
    }
    strict_transport_security {
      access_control_max_age_sec = each.value.security_headers_config.hsts_max_age
      include_subdomains         = each.value.security_headers_config.enable_include_subdomains_in_hsts
      preload                    = each.value.security_headers_config.enable_preload_in_hsts
      override                   = each.value.security_headers_config.is_override_hsts
    }
    xss_protection {
      mode_block = each.value.security_headers_config.set_xss_mode_as_block
      protection = each.value.security_headers_config.enable_xss_protection
      override   = each.value.security_headers_config.is_override_xss
    }
  }
}

locals {
  cache_policys = local.create ? { for k, v in var.cloudfront_cache_policy : k => v } : {}
}

resource "aws_cloudfront_cache_policy" "this" {
  for_each = local.cache_policys

  name        = each.value.unique_name
  comment     = each.value.description
  min_ttl     = each.value.min_ttl
  max_ttl     = each.value.max_ttl
  default_ttl = each.value.default_ttl
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = each.value.cache_rule.enable_cache_gzip
    enable_accept_encoding_brotli = each.value.cache_rule.enable_cache_brotli

    cookies_config {
      cookie_behavior = each.value.cache_rule.cookies_config.behavior
      dynamic "cookies" {
        for_each = toset(length(each.value.cache_rule.cookies_config.items) > 0 ? ["placeholder"] : [])
        content {
          items = each.value.cache_rule.cookies_config.items
        }
      }
    }

    headers_config {
      header_behavior = each.value.cache_rule.header_config.behavior
      dynamic "headers" {
        for_each = toset(length(each.value.cache_rule.header_config.items) > 0 ? ["placeholder"] : [])
        content {
          items = each.value.cache_rule.header_config.items
        }
      }
    }

    query_strings_config {
      query_string_behavior = each.value.cache_rule.query_strings_config.behavior
      dynamic "query_strings" {
        for_each = toset(length(each.value.cache_rule.query_strings_config.items) > 0 ? ["placeholder"] : [])
        content {
          items = each.value.cache_rule.query_strings_config.items
        }
      }
    }
  }
}


resource "aws_cloudfront_distribution" "this" {
  count   = local.create ? 1 : 0
  enabled = true

  aliases             = var.cloudfront_distribution.custom_domain_config.cnames
  default_root_object = "index.html"
  comment             = var.cloudfront_distribution.description
  web_acl_id          = var.cloudfront_distribution.waf_acl_id

  dynamic "origin" {
    for_each = var.cloudfront_distribution.origins

    content {
      domain_name              = origin.value.domain_name
      origin_id                = origin.value.origin_id
      origin_access_control_id = origin.value.custom_origin_config == null ? try(aws_cloudfront_origin_access_control.this[0].id, null) : null

      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config == null ? toset([]) : toset([origin.value.custom_origin_config])

        content {
          http_port                = custom_origin_config.value.http_port
          https_port               = custom_origin_config.value.https_port
          origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols     = custom_origin_config.value.origin_ssl_protocols
          origin_keepalive_timeout = custom_origin_config.value.origin_keepalive_timeout
          origin_read_timeout      = custom_origin_config.value.origin_read_timeout
        }
      }
    }
  }

  default_cache_behavior {
    allowed_methods            = var.cloudfront_distribution.default_cache_behavior.allowed_methods
    cached_methods             = var.cloudfront_distribution.default_cache_behavior.cached_methods
    target_origin_id           = var.cloudfront_distribution.default_cache_behavior.target_origin_id
    viewer_protocol_policy     = var.cloudfront_distribution.default_cache_behavior.viewer_protocol_policy
    cache_policy_id            = try(aws_cloudfront_cache_policy.this[0].id, null)
    origin_request_policy_id   = try(aws_cloudfront_origin_request_policy.this[0].id, null)
    response_headers_policy_id = try(aws_cloudfront_response_headers_policy.this[0].id, null)
  }
  dynamic "ordered_cache_behavior" {
    for_each = tolist(var.cloudfront_distribution.ordered_cache_behavior)
    iterator = ordered

    content {
      path_pattern               = ordered.value.path_pattern
      allowed_methods            = ordered.value.allowed_methods
      cached_methods             = ordered.value.cached_methods
      target_origin_id           = ordered.value.target_origin_id
      viewer_protocol_policy     = ordered.value.viewer_protocol_policy
      cache_policy_id            = try(aws_cloudfront_cache_policy.this[ordered.key + 1].id, null)
      origin_request_policy_id   = try(aws_cloudfront_origin_request_policy.this[ordered.key + 1].id, null)
      response_headers_policy_id = try(aws_cloudfront_response_headers_policy.this[ordered.key + 1].id, null)
    }
  }
  restrictions {
    geo_restriction {
      locations        = var.cloudfront_distribution.geo_restriction.locations
      restriction_type = var.cloudfront_distribution.geo_restriction.restriction_type
    }
  }
  dynamic "viewer_certificate" {
    for_each = tolist(var.cloudfront_distribution.custom_domain_config.use_default_domain ? [1] : [])
    content {
      cloudfront_default_certificate = true
    }
  }
  dynamic "viewer_certificate" {
    for_each = tolist(var.cloudfront_distribution.custom_domain_config.use_default_domain ? [] : [1])
    content {
      acm_certificate_arn      = var.cloudfront_distribution.custom_domain_config.acm_certificate_arn
      minimum_protocol_version = var.cloudfront_distribution.custom_domain_config.minimum_ssl_version
      ssl_support_method       = var.cloudfront_distribution.custom_domain_config.ssl_support_method
    }
  }

  tags = var.cloudfront_distribution.tags
}

resource "aws_acm_certificate" "this" {
  count = var.create_acm_certificate.create ? 1 : 0

  domain_name       = var.create_acm_certificate.domain_name_to_cert
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "this" {
  count = var.create_dns_record.create ? 1 : 0
  name  = var.create_acm_certificate.domain_name_to_cert
}

locals {
  domain_validation_options = var.create_dns_record.create ? { for k, v in aws_acm_certificate.this[0].domain_validation_options : k => v } : {}
}

resource "aws_route53_record" "this" {
  for_each = local.domain_validation_options

  allow_overwrite = var.create_dns_record.allow_overwrite_when_exist
  name            = each.value.resource_record_name
  records         = [each.value.resource_record_value]
  ttl             = var.create_dns_record.ttl
  type            = each.value.resource_record_type
  zone_id         = aws_route53_zone.this[0].zone_id
}
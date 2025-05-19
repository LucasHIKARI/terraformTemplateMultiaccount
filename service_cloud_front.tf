locals {
  origin_id_website    = "s3-website-bucket"
  origin_id_apigateway = "${local.lower_name}-apigateway"
  cdn_tags = merge(
    { Project = "${var.name}" },
    var.common_tags
  )
}

module "cdn" {
  source = "./modules/cloud-front"

  cloudfront_distribution = {
    create = true

    description = var.cdn_description
    waf_acl_id  = module.waf.waf.web_acl.arn
    origins = [
      {
        domain_name = module.s3_website_bucket.bucket.bucket_regional_domain_name
        origin_id   = local.origin_id_website
      },
      {
        domain_name = module.apigateway_to_alb.agv2.stage.domain_name
        origin_id   = local.origin_id_apigateway
        custom_origin_config = {
          http_port              = 80
          https_port             = 443
          origin_protocol_policy = "https-only"
        }
      }
    ]

    default_cache_behavior = {
      target_origin_id = local.origin_id_website
      allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods   = ["GET", "HEAD"]
    }

    ordered_cache_behavior = [
      {
        path_pattern     = "/api/*"
        target_origin_id = local.origin_id_apigateway
        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods   = ["GET", "HEAD"]
      }
    ]

    geo_restriction = {}

    custom_domain_config = {
      use_default_domain = true
    }

    tags = local.cdn_tags
  }

  # Origin Access Control
  cloudfront_oac = {
    create      = true
    name        = "${var.name}-${local.origin_id_website}-oac"
    origin_type = "s3"
  }

  cloudfront_monitor = {
    create                  = true
    enable_relatime_metrics = true
  }

  cloudfront_request_policy = [
    {
      unique_name = "${var.name}-${local.origin_id_website}-request-policy"
      description = "the request policy for the website"
      cookies_config = {
        behavior = "none"
      }
      headers_config = {
        behavior = "none"
      }
      query_strings_config = {
        behavior = "none"
      }
    },
    {
      unique_name = "${local.origin_id_apigateway}-request-policy"
      description = "the request policy for the APIGateway"
      cookies_config = {
        behavior = "none"
      }
      headers_config = {
        behavior = "none"
      }
      query_strings_config = {
        behavior = "none"
      }
    }
  ]

  cloudfront_response_policy = [
    {
      unique_name                  = "${var.name}-${local.origin_id_website}-response-policy"
      description                  = "the response policy for the website"
      security_headers_config      = {}
      server_timing_headers_config = {}
    },
    {
      unique_name                  = "${local.origin_id_apigateway}-response-policy"
      description                  = "the response policy for the APIGateway"
      security_headers_config      = {}
      server_timing_headers_config = {}
    }
  ]

  cloudfront_cache_policy = [
    {
      unique_name = "${var.name}-${local.origin_id_website}-cache-policy"
      description = "the cache policy for the website"
      cache_rule = {
        cookies_config       = {}
        header_config        = {}
        query_strings_config = {}
      }
    },
    {
      unique_name = "${local.origin_id_apigateway}-cache-policy"
      description = "the cache policy for the APIGateway"
      cache_rule = {
        cookies_config       = {}
        header_config        = {}
        query_strings_config = {}
      }
    }
  ]

}
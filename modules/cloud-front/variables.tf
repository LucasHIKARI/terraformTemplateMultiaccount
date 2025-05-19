variable "cloudfront_distribution" {
  description = "value"
  type = object({
    create = bool

    description = optional(string)
    waf_acl_id  = optional(string)

    origins = set(object({
      domain_name = string
      origin_id   = string
      custom_origin_config = optional(object({
        http_port  = number
        https_port = number
        # http-only,https-only,match-viewer
        origin_protocol_policy = string
        #SSLv3,TLSv1,TLSv1.1,TLSv1.2
        origin_ssl_protocols     = optional(set(string), ["TLSv1.2"])
        origin_keepalive_timeout = optional(number, 30)
        origin_read_timeout      = optional(number, 30)
      }))
    }))

    default_cache_behavior = object({
      target_origin_id       = string
      allowed_methods        = set(string)
      cached_methods         = set(string)
      viewer_protocol_policy = optional(string, "https-only")
    })
    ordered_cache_behavior = optional(set(object({
      path_pattern           = string
      target_origin_id       = string
      allowed_methods        = set(string)
      cached_methods         = set(string)
      viewer_protocol_policy = optional(string, "https-only")
    })), [])
    geo_restriction = object({
      locations        = optional(set(string), [])
      restriction_type = optional(string, "none")
    })

    custom_domain_config = object({
      use_default_domain  = optional(bool, true)
      cnames              = optional(set(string))
      acm_certificate_arn = optional(string)
      minimum_ssl_version = optional(string, "TLSv1.2_2021")
      ssl_support_method  = optional(string, "sni-only")
    })

    tags = optional(map(string))
  })
  default = {
    create  = false
    origins = []
    default_cache_behavior = {
      target_origin_id = ""
      allowed_methods  = []
      cached_methods   = []
    }
    geo_restriction      = {}
    custom_domain_config = {}
  }

  validation {
    condition     = var.cloudfront_distribution.create ? !(var.cloudfront_distribution.custom_domain_config.use_default_domain && var.cloudfront_distribution.custom_domain_config.acm_certificate_arn != null) : true
    error_message = "The custom cerficate and the default cerficate can be only one exist"
  }

  validation {
    condition     = var.cloudfront_distribution.create ? length(var.cloudfront_distribution.origins) > 0 : true
    error_message = "At least one origin must be specified"
  }

  validation {
    condition     = var.cloudfront_distribution.create ? contains(["TLSv1", "TLSv1_2016", "TLSv1.1_2016", "TLSv1.2_2018", "TLSv1.2_2019", "TLSv1.2_2021"], var.cloudfront_distribution.custom_domain_config.minimum_ssl_version) : true
    error_message = "Invalid SSL version"
  }

  validation {
    condition     = var.cloudfront_distribution.create ? length(setintersection(["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS", "TRACE", "CONNECT"], var.cloudfront_distribution.default_cache_behavior.allowed_methods)) == length(var.cloudfront_distribution.default_cache_behavior.allowed_methods) : true
    error_message = "Invalid http method specified in the allowed_methods"
  }

  validation {
    condition     = var.cloudfront_distribution.create ? length(setintersection(["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS", "TRACE", "CONNECT"], var.cloudfront_distribution.default_cache_behavior.cached_methods)) == length(var.cloudfront_distribution.default_cache_behavior.cached_methods) : true
    error_message = "Invalid http method specified in the cached_methods"
  }

  validation {
    condition     = var.cloudfront_distribution.create ? contains(["allow-all", "https-only", "redirect-to-https"], var.cloudfront_distribution.default_cache_behavior.viewer_protocol_policy) : true
    error_message = "The viewer protocol policy for the default_cache_behavior can be only one of [allow-all, https-only, redirect-to-https]"
  }

  validation {
    condition     = var.cloudfront_distribution.create ? contains(["none", "whitelist", "blacklist"], var.cloudfront_distribution.geo_restriction.restriction_type) : true
    error_message = "The type of geo_restriction can be only one of [none, whitelist, blacklist]"
  }
}

variable "cloudfront_oac" {
  description = "To config the CloudFront origin access control"
  type = object({
    create      = bool
    name        = string
    description = optional(string)
    origin_type = string
  })
  default = {
    create      = false
    name        = ""
    origin_type = "s3"
  }


  validation {
    condition     = var.cloudfront_oac.create ? length(var.cloudfront_oac.name) > 0 : true
    error_message = "Must to specify a name for the OAC"
  }

  validation {
    condition     = var.cloudfront_oac.create ? contains(["s3", "lambda", "mediapackagev2", "mediastore"], var.cloudfront_oac.origin_type) : true
    error_message = "The origin type must be either s3 or lambda"
  }
}

variable "cloudfront_vpc_origin" {
  description = "To config VPC as the origin for the CloudFront"
  type = object({
    create = bool
    endpoints = optional(list(object({
      name            = string
      arn             = string
      http_port       = optional(string, "80")
      https_port      = optional(string, "443")
      protocol_policy = optional(string, "https-only")
      ssl = optional(list(object({
        items    = list(string)
        quantity = number
      })), [])
    })), [])
  })
  default = {
    create = false
  }

  validation {
    condition     = var.cloudfront_vpc_origin.create ? alltrue([for v in var.cloudfront_vpc_origin.endpoints : contains(["http-only", "https-only"], v.protocol_policy)]) : true
    error_message = "The vpc origin protocol must either http-only or https-only"
  }
}

variable "cloudfront_monitor" {
  description = "To enable cloudfront metrics"
  type = object({
    create                  = bool
    enable_relatime_metrics = optional(bool, false)
  })
  default = {
    create = false
  }
}

variable "cloudfront_request_policy" {
  description = "To configure the origin request policy for the cloudfront"
  type = list(object({
    unique_name = string
    description = optional(string)
    cookies_config = object({
      behavior = optional(string, "none")
      items    = optional(set(string), [])
    })
    headers_config = object({
      behavior = optional(string, "none")
      items    = optional(set(string), [])
    })
    query_strings_config = object({
      behavior = optional(string, "none")
      items    = optional(set(string), [])
    })
  }))
  default = []

  validation {
    condition     = var.cloudfront_distribution.create || length(var.cloudfront_request_policy) == 0 ? alltrue([for v in var.cloudfront_request_policy : contains(["none", "whitelist", "all", "allExcept"], v.cookies_config.behavior)]) : true
    error_message = "The behavior must be the one of [none, whitelist, all, allExcept]"
  }

  validation {
    condition     = var.cloudfront_distribution.create || length(var.cloudfront_request_policy) == 0 ? alltrue([for v in var.cloudfront_request_policy : contains(["none", "whitelist", "allViewer", "allViewerAndWhitelistCloudFront", "allExcept"], v.headers_config.behavior)]) : true
    error_message = "The behavior must be the one of [none, whitelist, allViewer, allViewerAndWhitelistCloudFront, allExcept]"
  }

  validation {
    condition     = var.cloudfront_distribution.create || length(var.cloudfront_request_policy) == 0 ? alltrue([for v in var.cloudfront_request_policy : contains(["none", "whitelist", "all", "allExcept"], v.query_strings_config.behavior)]) : true
    error_message = "The behavior must be the one of [none, whitelist, all, allExcept]"
  }
}

variable "cloudfront_response_policy" {
  description = "To configure the response headers policy of the current cloudfront"
  type = list(object({
    unique_name = string
    description = optional(string)
    custom_headers_config = optional(set(object({
      header   = string
      override = bool
      value    = string
    })), [])
    remove_headers = optional(set(string), [])
    security_headers_config = object({
      content_security_policy             = optional(set(string), [])
      is_override_content_security_policy = optional(bool, false)

      is_override_content_type_options = optional(bool, true)

      is_deny_frame_options     = optional(bool, true)
      is_override_frame_options = optional(bool, true)

      referrer_policy             = optional(string, "no-referrer-when-downgrade")
      is_override_referrer_policy = optional(bool, true)

      hsts_max_age                      = optional(number, 315360000)
      enable_include_subdomains_in_hsts = optional(bool, true)
      enable_preload_in_hsts            = optional(bool, true)
      is_override_hsts                  = optional(bool, true)

      enable_xss_protection = optional(bool, true)
      set_xss_mode_as_block = optional(bool, true)
      is_override_xss       = optional(bool, true)
    })
    server_timing_headers_config = object({
      enable       = optional(bool, false)
      samping_rate = optional(number, 0)
    })
  }))
  default = []

  validation {
    condition     = var.cloudfront_distribution.create ? alltrue([for v in var.cloudfront_response_policy : length(v.security_headers_config.content_security_policy) <= 1]) : true
    error_message = "The max length of content_security_policy is 1"
  }

  validation {
    condition     = var.cloudfront_distribution.create || length(var.cloudfront_response_policy) == 0 ? alltrue([for v in var.cloudfront_response_policy : v.security_headers_config.hsts_max_age >= 315360000]) : true
    error_message = "The max-age value of HSTS must greater than 1 year"
  }

  validation {
    condition     = var.cloudfront_distribution.create || length(var.cloudfront_response_policy) == 0 ? alltrue([for v in var.cloudfront_response_policy : contains(["no-referrer", "no-referrer-when-downgrade", "origin", "origin-when-cross-origin", "same-origin", "strict-origin", "strict-origin-when-cross-origin"], v.security_headers_config.referrer_policy)]) : true
    error_message = "Invalid referrer policy value"
  }
}

variable "cloudfront_cache_policy" {
  description = "To configure the cache policy for the current cloudfront"
  type = list(object({
    unique_name = string
    min_ttl     = optional(number, 86400)
    max_ttl     = optional(number, 604800)
    default_ttl = optional(number, 86400)
    description = optional(string)
    cache_rule = object({
      enable_cache_brotli = optional(bool, false)
      enable_cache_gzip   = optional(bool, false)
      cookies_config = object({
        behavior = optional(string, "none")
        items    = optional(set(string), [])
      })
      header_config = object({
        behavior = optional(string, "none")
        items    = optional(set(string), [])
      })
      query_strings_config = object({
        behavior = optional(string, "none")
        items    = optional(set(string), [])
      })
    })
  }))
  default = []
}

variable "create_acm_certificate" {
  description = "To create ACM certificate for the custom domain name"
  type = object({
    create              = bool
    domain_name_to_cert = string
    tags                = optional(map(string))
  })
  default = {
    create              = false
    domain_name_to_cert = ""
  }

  validation {
    condition     = var.create_acm_certificate.create ? length(var.create_acm_certificate.domain_name_to_cert) > 0 : true
    error_message = "The length of domain name cannot be empty"
  }
}

variable "create_dns_record" {
  description = "To configure DNS record table"
  type = object({
    create                     = bool
    ttl                        = optional(number, 60)
    allow_overwrite_when_exist = optional(bool, true)
  })
  default = {
    create = false
  }
}
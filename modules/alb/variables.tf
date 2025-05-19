variable "alb_lb" {
  description = "To Configure the ALB(Application Load Balancer)"
  type = object({
    create                                      = bool
    unique_name                                 = optional(string)
    unique_name_prefix                          = optional(string)
    security_groups                             = optional(set(string), [])
    load_balancer_type                          = optional(string, "application")
    client_keep_alive                           = optional(number, 600)
    desync_mitigation_mode                      = optional(string, "defensive")
    drop_invalid_header_fields                  = optional(bool, true)
    enable_cross_zone_load_balancing            = optional(bool, true)
    enable_deletion_protection                  = optional(bool, false)
    enable_http2                                = optional(bool, true)
    enable_tls_version_and_cipher_suite_headers = optional(bool, false)
    enable_xff_client_port                      = optional(bool, true)
    enable_waf_fail_open                        = optional(bool, false)
    enable_zonal_shift                          = optional(bool, false)
    idle_timeout                                = optional(number, 60)
    is_internal                                 = optional(bool, false)
    preserve_host_header                        = optional(bool, true)
    xff_header_processing_mode                  = optional(string, "append")
    save_log_to_s3 = optional(set(object({
      log_for     = string
      bucket_name = string
      enabled     = optional(bool, true)
      key_prefix  = optional(string)
    })), [])
    subnets = optional(list(string))
    subnet_mapping = optional(set(object({
      subnet_id         = string
      allocation_id     = optional(string)
      private_ipv4_addr = optional(string)
    })), [])
    tags = optional(map(string), {})
  })
  default = {
    create = false
  }

  validation {
    condition     = var.alb_lb.create ? contains(["application", "gateway", "network"], var.alb_lb.load_balancer_type) : true
    error_message = "The load balancer type of ALB can only be the one of [application, gateway, network]"
  }

  validation {
    condition     = var.alb_lb.create ? alltrue([for v in var.alb_lb.save_log_to_s3 : contains(["access", "connection"], v.log_for)]) : true
    error_message = "The logs only be saved for access and connection operations"
  }

  validation {
    condition     = var.alb_lb.create ? var.alb_lb.client_keep_alive >= 60 && var.alb_lb.client_keep_alive <= 604800 : true
    error_message = "The value of client keep alive must be in the range of [60, 604800](in seconds)"
  }

  validation {
    condition     = var.alb_lb.create ? contains(["monitor", "defensive", "strictest"], var.alb_lb.desync_mitigation_mode) : true
    error_message = "The available mode can only be the one of [monitor, defensive, strictest] for the ALB to handles requests that might pose a security risk to an application due to HTTP desync"
  }

  validation {
    condition     = var.alb_lb.create && var.alb_lb.unique_name != null ? regex("^[a-zA-Z0-9]([a-zA-Z0-9-]{1,30}[a-zA-Z0-9])?$", var.alb_lb.unique_name) != "" : true
    error_message = "The name must be unique within your AWS account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen"
  }
}

variable "alb_lb_tgt_group" {
  description = "Configure the target group for the ALB"
  type = object({
    create                 = bool
    target_id              = optional(set(string), [])
    unique_name            = optional(string)
    unique_name_prefix     = optional(string)
    connection_termination = optional(bool)
    deregistration_delay   = optional(number, 60)
    lb_algorithm           = optional(string, "round_robin")
    port                   = optional(number, 80)
    preserve_client_ip     = optional(bool)
    protocol               = optional(string, "HTTP")
    protocol_version       = optional(string, "HTTP1")
    slow_start             = optional(number, 60)
    target_type            = optional(string, "instance")
    vpc_id                 = optional(string)
    health_check = optional(object({
      enabled             = optional(bool, true)
      healthy_threshold   = optional(number, 5)
      check_interval      = optional(number, 300)
      matcher             = optional(string, "200")
      path                = optional(string, "/")
      port                = optional(number, 80)
      protocol            = optional(string, "HTTP")
      timeout             = optional(number, 30)
      unhealthy_threshold = optional(number, 5)
    }))
    tags = optional(map(string), {})
  })
  default = {
    create = false
  }

  validation {
    condition     = var.alb_lb_tgt_group.create ? contains(["round_robin", "least_outstanding_requests", "weighted_random"], var.alb_lb_tgt_group.lb_algorithm) : true
    error_message = "The algorithm used by the ALB can only be the one of []"
  }

  validation {
    condition     = var.alb_lb_tgt_group.create && var.alb_lb_tgt_group.unique_name != null ? regex("^[a-zA-Z0-9]([a-zA-Z0-9-]{1,30}[a-zA-Z0-9])?$", var.alb_lb_tgt_group.unique_name) != "" : true
    error_message = "The name must be unique within your AWS account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen"
  }

  validation {
    condition     = var.alb_lb_tgt_group.create ? contains(["GENEVE", "HTTP", "HTTPS", "TCP", "TCP_UDP", "TLS", "UDP"], var.alb_lb_tgt_group.protocol) : true
    error_message = "Invalid protocol"
  }

  validation {
    condition     = var.alb_lb_tgt_group.create ? var.alb_lb_tgt_group.slow_start >= 30 && var.alb_lb_tgt_group.slow_start <= 900 : true
    error_message = "Warm up time in seconds for the newly added target in the ALB"
  }

  validation {
    condition     = var.alb_lb_tgt_group.create ? contains(["instance", "ip"], var.alb_lb_tgt_group.target_type) : true
    error_message = "The target type can be only the one of [instance, ip]"
  }

  validation {
    condition     = var.alb_lb_tgt_group.create && var.alb_lb_tgt_group.health_check != null ? var.alb_lb_tgt_group.health_check.check_interval >= 5 && var.alb_lb_tgt_group.health_check.check_interval <= 300 : true
    error_message = "The check interval time of health check must be in the range of [5,300](in seconds)"
  }
}

variable "alb_lb_listener" {
  description = "To configure the lisener for the ALB"
  type = object({
    create = bool
    default_action = set(object({
      # 1 - 50000
      order = optional(number)
      forward = optional(set(object({
        target_group_arn = string
        weight           = optional(number)
      })))
      fixed_response = optional(object({
        # text/plain, text/css, text/html, application/javascript and application/json
        content_type = string
        message_body = optional(string)
        status_code  = optional(number)
      }))
      redirect = optional(object({
        # HTTP_301, HTTP_302
        status_code = string
        path        = optional(string)
        port        = optional(number)
        # HTTP, HTTPS, #{protocol}
        protocol = optional(string)
        query    = optional(string)
      }))
    }))
    certificate_arn = optional(string)
    ssl_policy      = optional(string)
    port            = optional(number, 80)
    protocol        = optional(string, "HTTP")
    tags            = optional(map(string), {})
  })
  default = {
    create         = false
    default_action = []
  }

  validation {
    condition     = var.alb_lb_listener.create ? contains(["HTTP", "HTTPS"], var.alb_lb_listener.protocol) : true
    error_message = "This module currently supports only HTTP and HTTPS"
  }


  validation {
    condition     = var.alb_lb_listener.create ? alltrue([for v in var.alb_lb_listener.default_action : ((v.forward != null ? 1 : 0) + (v.fixed_response != null ? 1 : 0) + (v.redirect != null ? 1 : 0)) == 1]) : true
    error_message = "The type of forward,fixed_response,redirect can be specified only one in the same object"
  }
}
locals {
  access_logs     = var.alb_lb.create ? toset([for v in var.alb_lb.save_log_to_s3 : v if v.log_for == "access"]) : toset([])
  connection_logs = var.alb_lb.create ? toset([for v in var.alb_lb.save_log_to_s3 : v if v.log_for == "connection"]) : toset([])
}

resource "aws_lb" "this" {
  count                                       = var.alb_lb.create ? 1 : 0
  name                                        = var.alb_lb.unique_name
  name_prefix                                 = var.alb_lb.unique_name_prefix
  security_groups                             = var.alb_lb.security_groups
  ip_address_type                             = "ipv4"
  load_balancer_type                          = var.alb_lb.load_balancer_type
  client_keep_alive                           = var.alb_lb.client_keep_alive
  desync_mitigation_mode                      = var.alb_lb.desync_mitigation_mode
  drop_invalid_header_fields                  = var.alb_lb.drop_invalid_header_fields
  enable_cross_zone_load_balancing            = var.alb_lb.enable_cross_zone_load_balancing
  enable_deletion_protection                  = var.alb_lb.enable_deletion_protection
  enable_http2                                = var.alb_lb.enable_http2
  enable_tls_version_and_cipher_suite_headers = var.alb_lb.enable_tls_version_and_cipher_suite_headers
  enable_xff_client_port                      = var.alb_lb.enable_xff_client_port
  enable_waf_fail_open                        = var.alb_lb.enable_waf_fail_open
  idle_timeout                                = var.alb_lb.idle_timeout
  internal                                    = var.alb_lb.is_internal
  preserve_host_header                        = var.alb_lb.preserve_host_header
  xff_header_processing_mode                  = var.alb_lb.xff_header_processing_mode
  subnets                                     = var.alb_lb.subnets
  tags                                        = var.alb_lb.tags

  dynamic "subnet_mapping" {
    for_each = var.alb_lb.subnet_mapping
    content {
      subnet_id            = subnet_mapping.value.subnet_id
      allocation_id        = subnet_mapping.value.allocation_id
      private_ipv4_address = subnet_mapping.value.private_ipv4_addr
    }
  }

  dynamic "access_logs" {
    for_each = local.access_logs

    content {
      bucket  = access_logs.value.bucket_name
      enabled = access_logs.value.enabled
      prefix  = access_logs.value.key_prefix
    }
  }

  dynamic "connection_logs" {
    for_each = local.connection_logs

    content {
      bucket  = connection_logs.value.bucket_name
      enabled = connection_logs.value.enabled
      prefix  = connection_logs.value.key_prefix
    }
  }
}

locals {
  create_tgt_grp = var.alb_lb_tgt_group.create
  health_check   = local.create_tgt_grp && var.alb_lb_tgt_group.health_check != null ? toset([var.alb_lb_tgt_group.health_check]) : toset([])
  target_ids     = local.create_tgt_grp ? { for k, v in tolist(var.alb_lb_tgt_group.target_id) : k => v } : tomap({})
}

resource "aws_lb_target_group" "this" {
  count                         = local.create_tgt_grp ? 1 : 0
  connection_termination        = var.alb_lb_tgt_group.connection_termination
  deregistration_delay          = var.alb_lb_tgt_group.deregistration_delay
  load_balancing_algorithm_type = var.alb_lb_tgt_group.lb_algorithm
  name                          = var.alb_lb_tgt_group.unique_name
  name_prefix                   = var.alb_lb_tgt_group.unique_name_prefix
  port                          = var.alb_lb_tgt_group.port
  preserve_client_ip            = var.alb_lb_tgt_group.preserve_client_ip
  protocol_version              = var.alb_lb_tgt_group.protocol_version
  protocol                      = var.alb_lb_tgt_group.protocol
  slow_start                    = var.alb_lb_tgt_group.slow_start
  target_type                   = var.alb_lb_tgt_group.target_type
  ip_address_type               = var.alb_lb_tgt_group.target_type == "ip" ? "ipv4" : null
  vpc_id                        = var.alb_lb_tgt_group.vpc_id
  tags                          = var.alb_lb_tgt_group.tags

  dynamic "health_check" {
    for_each = local.health_check

    content {
      enabled             = health_check.value.enabled
      healthy_threshold   = health_check.value.healthy_threshold
      interval            = health_check.value.check_interval
      matcher             = health_check.value.matcher
      path                = health_check.value.path
      port                = health_check.value.port
      protocol            = health_check.value.protocol
      timeout             = health_check.value.timeout
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }
}

resource "aws_lb_target_group_attachment" "this" {
  for_each         = local.target_ids
  target_group_arn = aws_lb_target_group.this[0].arn
  target_id        = each.value
}

locals {
  create_listener = var.alb_lb.create && var.alb_lb_listener.create
  listener_actions = local.create_listener ? toset([
    for v in var.alb_lb_listener.default_action : {
      order = v.order
      type = v.forward != null ? "forward" : (
        v.fixed_response != null ? "fixed-response" : (
          # "xxxxx" will trigger the terraform error
          v.redirect != null ? "redirect" : "xxxxx"
        )
      )
      forward        = v.forward != null ? (length(v.forward) == 0 ? toset([{ target_group_arn = aws_lb_target_group.this[0].arn, weight = null }]) : v.forward) : toset([])
      fixed_response = v.fixed_response != null ? toset([v.fixed_response]) : toset([])
      redirect       = v.redirect != null ? toset([v.redirect]) : toset([])
    }
  ]) : toset([])
}

resource "aws_lb_listener" "this" {
  count = local.create_listener ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  certificate_arn   = var.alb_lb_listener.certificate_arn
  ssl_policy        = var.alb_lb_listener.ssl_policy
  port              = var.alb_lb_listener.port
  protocol          = var.alb_lb_listener.protocol
  tags              = var.alb_lb_listener.tags

  dynamic "default_action" {
    for_each = local.listener_actions

    content {
      order = default_action.value.order
      type  = default_action.value.type

      forward {
        dynamic "target_group" {
          for_each = default_action.value.forward
          content {
            arn    = target_group.value.target_group_arn
            weight = target_group.value.weight
          }
        }
      }
      # dynamic "forward" {
      #   for_each = default_action.value.forward
      #   content {
      #     target_group {
      #       arn = forward.value.target_group_arn
      #     }
      #   }
      # }

      dynamic "fixed_response" {
        for_each = default_action.value.fixed_response
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }

      dynamic "redirect" {
        for_each = default_action.value.redirect
        content {
          status_code = redirect.value.status_code
          path        = redirect.value.path
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          query       = redirect.value.query
        }
      }
    }
  }
}

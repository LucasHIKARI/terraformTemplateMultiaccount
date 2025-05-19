output "alb" {
  description = "The information for the ALB"
  value = {
    lb = {
      arn        = try(aws_lb.this[0].arn, null)
      arn_suffix = try(aws_lb.this[0].arn_suffix, null)
      dns_name   = try(aws_lb.this[0].dns_name, null)
      id         = try(aws_lb.this[0].id, null)
      zone_id    = try(aws_lb.this[0].zone_id, null)
    }
    target_group = {
      arn        = try(aws_lb_target_group.this[0].arn, null)
      arn_suffix = try(aws_lb_target_group.this[0].arn_suffix, null)
      id         = try(aws_lb_target_group.this[0].id, null)
      name       = try(aws_lb_target_group.this[0].name, null)
      lb_arns    = try(aws_lb_target_group.this[0].load_balancer_arns, null)
    }
    listener = {
      arn = try(aws_lb_listener.this[0].arn, null)
      id  = try(aws_lb_listener.this[0].id, null)
    }
  }
}
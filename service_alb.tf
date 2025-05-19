locals {
  alb_lb_name         = "${local.lower_name}-alb"
  alb_lb_tgt_grp_name = "${local.alb_lb_name}-for-ec2"
}

module "alb_to_server" {
  source = "./modules/alb"

  alb_lb = {
    create          = true
    unique_name     = local.alb_lb_name
    is_internal     = true
    subnets         = [local.ec2_instance_subnet_id, element(module.vpc.vpc.subnets, var.ec2_instance_subnet_num + 1).id]
    security_groups = [module.vpc.vpc.security_group["ALB"].id]
    save_log_to_s3 = [
      {
        log_for     = "access"
        bucket_name = module.s3_logger_bucket.bucket.bucket_name
        enabled     = true
        key_prefix  = "alb/access"
      },
      {
        log_for     = "connection"
        bucket_name = module.s3_logger_bucket.bucket.bucket_name
        enabled     = true
        key_prefix  = "alb/connection"
      }
    ]
  }

  alb_lb_tgt_group = {
    create      = true
    unique_name = local.alb_lb_tgt_grp_name
    target_id   = [module.ec2_instance.id]
    vpc_id      = module.vpc.vpc.id
    port        = 8000
    protocol    = "HTTP"
    health_check = {
      enabled           = true
      port              = 8000
      check_interval    = 300
      healthy_threshold = 2
      timeout           = 20
      protocol          = "HTTP"
      path              = "/aux/healthcheck"
    }
  }

  alb_lb_listener = {
    create   = true
    port     = 80
    protocol = "HTTP"
    default_action = [{
      forward = []
    }]
  }
}
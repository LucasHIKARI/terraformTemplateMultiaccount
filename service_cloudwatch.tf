locals {
  cw_common_tags = merge(
    { Project = "${var.name}" },
    var.common_tags
  )
}

module "cloudwatch" {
  source = "./modules/cloud-watch"

  topic_name = module.sns.sns_topic_arn

  # EC2インスタンス監視用パラメータ
  ec2_instance_id = module.ec2_instance.id
  environment     = var.environment

  # S3バケット監視用パラメータ
  s3_bucket_name = module.s3_data_bucket.bucket.bucket_name

  # CloudWatchログ設定
  cloudwatch_log_retention = var.cloudwatch_log_retention
  app_logs_name            = "${var.app_logs_name}/${local.lower_name}"
  cw_log_group = {
    EC2 = {
      create            = true
      unique_name       = "${var.app_logs_name}/${local.lower_name}"
      log_group_class   = "STANDARD"
      retention_in_days = var.cloudwatch_log_retention
      tags              = local.cw_common_tags
    }
    APIGateway = {
      create            = true
      unique_name       = "/aws/apigatewayv2/${local.lower_name}"
      log_group_class   = "STANDARD"
      retention_in_days = var.cloudwatch_log_retention
      tags              = local.cw_common_tags
    }
  }

  cw_log_stream = [
    {
      create            = true
      bind_to_log_group = "APIGateway"
      name              = module.apigateway_to_alb.agv2.api.id
    },
    {
      create            = true
      bind_to_log_group = "EC2"
      name              = "${module.ec2_instance.id}-app.log"
    },
    {
      create            = true
      bind_to_log_group = "EC2"
      name              = "${module.ec2_instance.id}-error.log"
    },
    {
      create            = true
      bind_to_log_group = "EC2"
      name              = "${module.ec2_instance.id}-access.log"
    },
  ]

  # API Gateway監視設定
  api_gateway_names = var.api_gateway_names

  ok_actions    = module.sns.sns_topic_arn
  alarm_actions = module.sns.sns_topic_arn

  # アラーム名設定
  ec2_cpu_alarm_name    = "${var.name}-${var.ec2_cpu_alarm_name}"
  ec2_mem_alarm_name    = "${var.name}-${var.ec2_mem_alarm_name}"
  ec2_disk_alarm_name   = "${var.name}-${var.ec2_disk_alarm_name}"
  s3_storage_alarm_name = "${var.name}-${var.s3_storage_alarm_name}"

  # Djangoエラー監視設定
  django_5xx_errors_filter_name = "${var.name}-${var.django_5xx_errors_filter_name}"
  django_4xx_error_filter_name  = "${var.name}-${var.django_4xx_error_filter_name}"
  django_5xx_error_alarm_name   = "${var.name}-${var.django_5xx_error_alarm_name}"
  django_4xx_error_alarm_name   = "${var.name}-${var.django_4xx_error_alarm_name}"

  # API Gatewayエラー監視設定
  External_API_Gateway_Errors_alarm_name = "${var.name}-${var.External_API_Gateway_Errors_alarm_name}"
  Internal_API_Gateway_Errors_alarm_name = "${var.name}-${var.Internal_API_Gateway_Errors_alarm_name}"
  API_Gateway_High_Latency_alarm_name    = "${var.name}-${var.API_Gateway_High_Latency_alarm_name}"

  cw_metric_alarm = {
    ALB5XX = {
      create              = true
      alarm_name          = "${var.name}-ALB-5XXErrRate"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      namespace           = "AWS/ApplicationELB"
      metric_name         = "HTTPCode_ELB_5XX_Count"
      period_in_sec       = 60
      statistic           = "Sum"
      threshold           = 1
      alarm_description   = "This metric monitors 5xx errors from ALB"
      tags                = local.cw_common_tags
    }
    ALB4XX = {
      create              = true
      alarm_name          = "${var.name}-ALB-4XXErrRate"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      namespace           = "AWS/ApplicationELB"
      metric_name         = "HTTPCode_ELB_4XX_Count"
      period_in_sec       = 60
      statistic           = "Sum"
      threshold           = 1
      alarm_description   = "This metric monitors 4xx errors from ALB"
      tags                = local.cw_common_tags
    }
  }
}

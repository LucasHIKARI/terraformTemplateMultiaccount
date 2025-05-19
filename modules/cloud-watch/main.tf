resource "aws_cloudwatch_log_group" "app_logs" {
  for_each = { for k, v in var.cw_log_group : k => v if v.create }

  name              = each.value.unique_name
  skip_destroy      = each.value.skip_destroy
  log_group_class   = each.value.log_group_class
  retention_in_days = each.value.retention_in_days
  kms_key_id        = each.value.kms_key_id
  tags              = each.value.tags
}

resource "aws_cloudwatch_log_stream" "this" {
  for_each = { for k, v in var.cw_log_stream : k => v if v.create }

  name           = each.value.name
  log_group_name = aws_cloudwatch_log_group.app_logs[each.value.bind_to_log_group].name
}

# インフラ監視（ec2_cpu）
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = var.ec2_cpu_alarm_name
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  evaluation_periods  = 1
  period              = 60
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  dimensions = {
    InstanceId = var.ec2_instance_id
  }
  alarm_description = "EC2 CPU 使用率が高すぎます。"
  alarm_actions     = [var.alarm_actions]
  ok_actions        = [var.ok_actions]
  tags = {
    Environment = var.environment
    Type        = "Infrastructure"
  }
}
# インフラ監視（EC2 Memory） 
resource "aws_cloudwatch_metric_alarm" "ec2_mem" {
  alarm_name          = var.ec2_mem_alarm_name
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  evaluation_periods  = 1
  period              = 60
  namespace           = "CWAgent"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  dimensions = {
    InstanceId = var.ec2_instance_id
  }
  alarm_description = "EC2 メモリ使用率が高い"
  alarm_actions     = [var.alarm_actions]
  ok_actions        = [var.ok_actions]
  tags = {
    Environment = var.environment
    Type        = "Infrastructure"
  }
}

# インフラ監視（ec2_disk）
resource "aws_cloudwatch_metric_alarm" "ec2_disk" {
  alarm_name          = var.ec2_disk_alarm_name
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  evaluation_periods  = 1
  period              = 600
  namespace           = "CWAgent"
  metric_name         = "DiskSpaceUtilization"
  statistic           = "Average"
  dimensions = {
    InstanceId = var.ec2_instance_id
    Filesystem = "/dev/xvda1"
    MountPath  = "/"
  }
  alarm_description = "EC2のディスクの空き容量が不足しています。"
  alarm_actions     = [var.alarm_actions]
}

# ストレージ監視（S3）
resource "aws_cloudwatch_metric_alarm" "s3_storage" {
  alarm_name          = var.s3_storage_alarm_name
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  evaluation_periods  = 1
  period              = 600
  namespace           = "AWS/S3"
  metric_name         = "BucketSizeBytes"
  statistic           = "Average"
  dimensions = {
    BucketName  = var.s3_bucket_name
    StorageType = "StandardStorage"
  }
  alarm_description = "S3 バケットの使用量が高くなっています"
  alarm_actions     = [var.alarm_actions]
}

# Django 5xxエラー監視用フィルター
resource "aws_cloudwatch_log_metric_filter" "django_5xx_errors" {
  name           = var.django_5xx_errors_filter_name
  log_group_name = aws_cloudwatch_log_group.app_logs["EC2"].name
  pattern        = "ERROR"
  metric_transformation {
    name      = "Django5xxErrorCount"
    namespace = "Custom/Django"
    value     = "1"
    unit      = "Count"
  }
}

# Django 4xxエラー監視用フィルター
resource "aws_cloudwatch_log_metric_filter" "django_4xx_errors" {
  name           = var.django_4xx_error_filter_name
  log_group_name = aws_cloudwatch_log_group.app_logs["EC2"].name
  pattern        = "WARNING"
  metric_transformation {
    name      = "Django4xxErrorCount"
    namespace = "Custom/Django"
    value     = "1"
    unit      = "Count"
  }
}

# Django 5xxエラーアラーム
resource "aws_cloudwatch_metric_alarm" "django_5xx_error_alarm" {
  alarm_name          = var.django_5xx_error_alarm_name
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1 # 5xxエラーは1回で警告
  evaluation_periods  = 1
  period              = 60
  namespace           = "Custom/Django"
  metric_name         = "Django5xxErrorCount"
  statistic           = "Sum"
  alarm_description   = "Django アプリケーションで5xxエラーが発生しました"
  alarm_actions       = [var.alarm_actions]
  ok_actions          = [var.ok_actions]
  tags = {
    Environment = var.environment
    Type        = "Application"
  }
}

# Django 4xxエラーアラーム
resource "aws_cloudwatch_metric_alarm" "django_4xx_error_alarm" {
  alarm_name          = var.django_4xx_error_alarm_name
  comparison_operator = "GreaterThanThreshold"
  threshold           = 5 # 4xxエラーは5回で警告
  evaluation_periods  = 1
  period              = 60
  namespace           = "Custom/Django"
  metric_name         = "Django4xxErrorCount"
  statistic           = "Sum"
  alarm_description   = "Django アプリケーションで4xxエラーが多発しています"
  alarm_actions       = [var.alarm_actions]
  ok_actions          = [var.ok_actions]
  tags = {
    Environment = var.environment
    Type        = "Application"
  }
}

# 外部API Gateway監視
resource "aws_cloudwatch_metric_alarm" "external_api_errors" {
  alarm_name          = var.External_API_Gateway_Errors_alarm_name
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1
  evaluation_periods  = 1
  period              = 300
  namespace           = "AWS/ApiGateway"
  metric_name         = "5XXError"
  statistic           = "Sum"
  dimensions = {
    ApiName = "binah_external_api_${var.environment}"
    Stage   = var.environment
  }
  alarm_description = "外部API Gatewayで5XXエラーが発生しました"
  alarm_actions     = [var.alarm_actions]
  ok_actions        = [var.ok_actions]
  tags = {
    Environment = var.environment
    Type        = "APIGateway"
  }
}

# 内部API Gateway監視
resource "aws_cloudwatch_metric_alarm" "internal_api_errors" {
  alarm_name          = var.Internal_API_Gateway_Errors_alarm_name
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1
  evaluation_periods  = 1
  period              = 300
  namespace           = "AWS/ApiGateway"
  metric_name         = "5XXError"
  statistic           = "Sum"
  dimensions = {
    ApiName = "binah_internal_api_${var.environment}"
    Stage   = var.environment
  }
  alarm_description = "内部API Gatewayで5XXエラーが発生しました"
  alarm_actions     = [var.alarm_actions]
  ok_actions        = [var.ok_actions]
  tags = {
    Environment = var.environment
    Type        = "APIGateway"
  }
}

# レイテンシー監視
resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = var.API_Gateway_High_Latency_alarm_name
  comparison_operator = "GreaterThanThreshold"
  threshold           = 2000 # 2秒
  evaluation_periods  = 1
  period              = 300
  namespace           = "AWS/ApiGateway"
  metric_name         = "Latency"
  statistic           = "Average"
  dimensions = {
    ApiName = "binah_external_api_${var.environment}"
    Stage   = var.environment
  }
  alarm_description = "API Gatewayのレイテンシーが高くなっています"
  alarm_actions     = [var.alarm_actions]
  tags = {
    Environment = var.environment
    Type        = "APIGateway"
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = {
    for k, v in var.cw_metric_alarm : k => v if v.create
  }

  alarm_name          = each.value.alarm_name
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  threshold           = each.value.threshold
  period              = each.value.period_in_sec
  namespace           = each.value.namespace
  metric_name         = each.value.metric_name
  statistic           = each.value.statistic
  dimensions          = each.value.dimensions
  actions_enabled     = each.value.enable_actions
  alarm_actions       = each.value.alarm_actions
  tags                = each.value.tags
}

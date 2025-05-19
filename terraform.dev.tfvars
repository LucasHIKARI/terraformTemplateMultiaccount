#################################################################
#  WARNING
#               気をつけてください
#  このファイルの変数は開発用です
#
#  本番環境ではterraform.prod.tfvarsを使用してください
#################################################################

name        = "BinahAI-test"
region      = "ap-northeast-1"
environment = "Development"

ec2_instance_type      = "t2.micro"
ec2_instance_ip_number = 2025
ec2_keyname            = "BinahAi"

vpc_cidr                   = "172.25.0.0/16"
vpc_route_destination_cidr = "0.0.0.0/0"
vpc_subnet_nums            = 4

# CloudWatchの設定
cloudwatch_log_retention = 0
app_logs_name            = "/aws/ec2/development/application"

# SNS
alert_emails = [
  "lv478058682@gmail.com"
]


# API Gateway監視設定
api_gateway_names = {
  external = "binah-external-api"
  internal = "binah-internal-api"
}

# アラーム名設定
ec2_cpu_alarm_name    = "EC2-High-CPU"
ec2_mem_alarm_name    = "EC2-High-Memory"
ec2_disk_alarm_name   = "EC2-High-Disk"
s3_storage_alarm_name = "S3-Storage-Alert"

# Djangoエラー監視設定
django_5xx_errors_filter_name = "django-5xx-error-filter"
django_4xx_error_filter_name  = "django-4xx-error-filter"
django_5xx_error_alarm_name   = "django-5xx-error-alarm"
django_4xx_error_alarm_name   = "django-4xx-error-alarm"

# API Gatewayエラー監視設定
External_API_Gateway_Errors_alarm_name = "External-API-Gateway-Errors"
Internal_API_Gateway_Errors_alarm_name = "Internal-API-Gateway-Errors"
API_Gateway_High_Latency_alarm_name    = "API-Gateway-High-Latency"

enable_bucket_object_lock = {
  for_data    = true
  for_logger  = true
  for_website = true
}

object_lock_rule = {
  "for_data" = {
    days             = 1
    object_lock_mode = "GOVERNANCE"
  }
  "for_logger" = {
    days             = 1
    object_lock_mode = "GOVERNANCE"
  }
  "for_website" = {
    days             = 1
    object_lock_mode = "GOVERNANCE"
  }
}

enable_block_public_access = {
  "for_data" = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
  "for_logger" = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
  "for_website" = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
}

upload_website_to_s3 = {
  local_path = "./client"
}

upload_server_to_s3 = {
  local_path = "./server"
}


common_tags = {
  "Environment" = "Development"
}

cdn_description = "BinahAI development"

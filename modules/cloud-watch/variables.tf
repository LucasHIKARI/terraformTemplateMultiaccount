variable "topic_name" {
  type        = string
  description = "SNSトピックの名前"
}

variable "ec2_instance_id" {
  type        = string
  description = "監視対象のEC2インスタンスID"
}

variable "environment" {
  type        = string
  description = "デプロイ環境名（例: dev, staging, prod）"
}

variable "s3_bucket_name" {
  type        = string
  description = "監視対象のS3バケット名"
}

variable "cloudwatch_log_retention" {
  type        = number
  description = "CloudWatchロググループの保持期間（日数）"
}

variable "app_logs_name" {
  type        = string
  description = "app_logs_name"
}

variable "ok_actions" {
  type        = string
  description = "ok_actions"
}

variable "alarm_actions" {
  type        = string
  description = "alarm_actions"
}


variable "api_gateway_names" {
  description = "API Gateway names to monitor"
  type = object({
    external = string
    internal = string
  })
}

variable "ec2_cpu_alarm_name" {
  type        = string
  description = "EC2 CPUモニタリングアラームの名前"
}

variable "ec2_mem_alarm_name" {
  type        = string
  description = "EC2 メモリモニタリングアラームの名前"
}

variable "ec2_disk_alarm_name" {
  type        = string
  description = "EC2 ディスクモニタリングアラームの名前"
}

variable "s3_storage_alarm_name" {
  type        = string
  description = "S3 ストレージモニタリングアラームの名前"
}

variable "django_5xx_errors_filter_name" {
  type        = string
  description = "Django 5xxエラーフィルターの名前"
}

variable "django_4xx_error_filter_name" {
  type        = string
  description = "Django 4xxエラーフィルターの名前"
}

variable "django_5xx_error_alarm_name" {
  type        = string
  description = "Django 5xxエラーアラームの名前"
}

variable "django_4xx_error_alarm_name" {
  type        = string
  description = "Django 4xxエラーアラームの名前"
}

variable "External_API_Gateway_Errors_alarm_name" {
  type        = string
  description = "外部API Gateway エラーアラームの名前"
}

variable "Internal_API_Gateway_Errors_alarm_name" {
  type        = string
  description = "内部API Gateway エラーアラームの名前"
}

variable "API_Gateway_High_Latency_alarm_name" {
  type        = string
  description = "API Gateway レイテンシーアラームの名前"
}


variable "cw_log_group" {
  description = "create Cloudwatch log group"
  type = map(object({
    create       = bool
    unique_name  = optional(string)
    skip_destroy = optional(bool)
    #STANDARD or INFREQUENT_ACCESS
    log_group_class = optional(string)
    #1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653, and 0. 
    retention_in_days = optional(number)
    kms_key_id        = optional(string)
    tags              = optional(map(string))
  }))
  default = {}
}

variable "cw_log_stream" {
  description = "create log stream for a log group"
  type = list(object({
    create = bool
    name   = string
    # the key of cw_log_group
    bind_to_log_group = string
  }))
  default = []
}


variable "cw_metric_alarm" {
  description = "Create a CloudWatch Metric Alarm"
  type = map(object({
    create     = bool
    alarm_name = string
    # GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold. Additionally, the values LessThanLowerOrGreaterThanUpperThreshold, LessThanLowerThreshold, and GreaterThanUpperThreshold
    comparison_operator = string
    evaluation_periods  = number
    threshold           = optional(number)
    # Valid values are 10, 30, or any multiple of 60
    period_in_sec = optional(number)
    namespace     = optional(string)
    metric_name   = optional(string)
    #  SampleCount, Average, Sum, Minimum, Maximum
    statistic      = optional(string)
    dimensions     = optional(map(string))
    alarm_actions  = optional(set(string))
    enable_actions = optional(bool, false)
    tags           = optional(map(string), {})
  }))
  default = {}
}
# CloudWatch関連の変数定義
variable "environment" {
  type        = string
  description = "デプロイ環境名（例: dev, staging, prod）"
}
variable "cloudwatch_log_retention" {
  type        = number
  description = "CloudWatchロググループの保持期間（日数）"
}

variable "app_logs_name" {
  type        = string
  description = "アプリケーションログの名前"
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
  default     = "django-5xx-errors"
}

variable "django_4xx_error_filter_name" {
  type        = string
  description = "Django 4xxエラーフィルターの名前"
  default     = "django-4xx-errors"
}

variable "django_5xx_error_alarm_name" {
  type        = string
  description = "Django 5xxエラーアラームの名前"
  default     = "django-5xx-error-alarm"
}

variable "django_4xx_error_alarm_name" {
  type        = string
  description = "Django 4xxエラーアラームの名前"
  default     = "django-4xx-error-alarm"
}

variable "External_API_Gateway_Errors_alarm_name" {
  type        = string
  description = "外部API Gateway エラーアラームの名前"
  default     = "external-api-gateway-errors"
}

variable "Internal_API_Gateway_Errors_alarm_name" {
  type        = string
  description = "内部API Gateway エラーアラームの名前"
  default     = "internal-api-gateway-errors"
}

variable "API_Gateway_High_Latency_alarm_name" {
  type        = string
  description = "API Gateway レイテンシーアラームの名前"
  default     = "api-gateway-high-latency"
}

variable "alert_emails" {
  type        = list(string)
  description = "アラート通知を送信するメールアドレスのリスト"
  default     = []  
}
# SNSトピックの名前（例: "alert-topic"）
variable "topic_name" {
  type        = string
  description = "SNSトピックの名前"
}

variable "alert_emails" {
  type        = list(string)
  description = "アラート通知を送信するメールアドレスのリスト"
  default     = []
}

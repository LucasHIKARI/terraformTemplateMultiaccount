# SNS Topic
resource "aws_sns_topic" "alerts" {
  name = var.topic_name
}

# SNS Topic Email Subscription
resource "aws_sns_topic_subscription" "email" {
  count     = length(var.alert_emails)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}



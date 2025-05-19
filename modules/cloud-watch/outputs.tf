output "log_group" {
  description = "The information of AWS CloudWatch Log Group"
  value = { for k, v in aws_cloudwatch_log_group.app_logs : k => {
    arn  = try(v.arn, null)
    name = try(v.name, null)
  } }
}

output "rendered_log_group_name" {
  value = aws_cloudwatch_log_metric_filter.django_4xx_errors.log_group_name
}
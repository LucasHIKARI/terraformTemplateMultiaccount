module "sns" {
  source       = "./modules/sns"
  topic_name   = "${var.name}-alerts"
  alert_emails = var.alert_emails
}

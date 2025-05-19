resource "aws_apigatewayv2_api" "this" {
  count = var.ag_api.create ? 1 : 0

  name                         = var.ag_api.name
  description                  = var.ag_api.description
  protocol_type                = var.ag_api.protocol
  disable_execute_api_endpoint = var.ag_api.disable_execute_api_endpoint
  tags                         = var.ag_api.tags
  version                      = var.ag_api.version
}


resource "aws_apigatewayv2_integration" "this" {
  count = var.ag_integration.create ? 1 : 0

  api_id      = aws_apigatewayv2_api.this[0].id
  description = var.ag_integration.description

  integration_type     = var.ag_integration.integration_type
  integration_uri      = var.ag_integration.integration_uri
  connection_type      = var.ag_integration.connection_type
  integration_method   = var.ag_integration.integration_method
  connection_id        = aws_apigatewayv2_vpc_link.this[0].id
  timeout_milliseconds = var.ag_integration.timeout_milliseconds
}

resource "aws_apigatewayv2_route" "this" {
  for_each = { for k, v in var.ag_route.route_keys : k => v if var.ag_route.create && var.ag_api.create && var.ag_integration.create }

  api_id    = aws_apigatewayv2_api.this[0].id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.this[0].id}"
}

resource "aws_apigatewayv2_vpc_link" "this" {
  count = var.ag_vpc_link.create ? 1 : 0

  name               = var.ag_vpc_link.name
  security_group_ids = var.ag_vpc_link.security_group_ids
  subnet_ids         = var.ag_vpc_link.subnet_ids
  tags               = var.ag_vpc_link.tags
}

resource "aws_apigatewayv2_stage" "this" {
  count = var.ag_stage.create && var.ag_api.create ? 1 : 0

  api_id      = aws_apigatewayv2_api.this[0].id
  name        = var.ag_stage.name
  auto_deploy = var.ag_stage.auto_deploy

  dynamic "access_log_settings" {
    for_each = tolist(can(var.ag_stage.access_log_settings) ? [var.ag_stage.access_log_settings] : [])

    content {
      destination_arn = access_log_settings.value.cloudwatch_log_group_arn
      format          = access_log_settings.value.log_format
    }
  }

  dynamic "default_route_settings" {
    for_each = tolist(can(var.ag_stage.default_route_settings) ? [var.ag_stage.default_route_settings] : [])
    content {
      # data_trace_enabled       = default_route_settings.value.enable_data_trace
      detailed_metrics_enabled = default_route_settings.value.enable_detailed_metrics
      # logging_level            = default_route_settings.value.log_level
      throttling_burst_limit = default_route_settings.value.limit_throttling_burst
      throttling_rate_limit  = default_route_settings.value.limit_throttling_rate
    }
  }

  dynamic "route_settings" {
    for_each = var.ag_stage.route_settings

    content {
      route_key = route_settings.value.route_key
      # data_trace_enabled       = route_settings.value.enable_data_trace
      detailed_metrics_enabled = route_settings.value.enable_detailed_metrics
      # logging_level            = route_settings.value.log_level
      throttling_burst_limit = route_settings.value.limit_throttling_burst
      throttling_rate_limit  = route_settings.value.limit_throttling_rate
    }
  }
}

resource "aws_apigatewayv2_deployment" "this" {
  api_id      = aws_apigatewayv2_api.this[0].id
  description = "To Deploy API Gatewayv2"

  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_integration.this),
      jsonencode(aws_apigatewayv2_route.this),
    ])))
  }

  lifecycle {
    create_before_destroy = true
  }
}
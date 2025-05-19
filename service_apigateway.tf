module "apigateway_to_alb" {
  source = "./modules/api-gatewayv2"
  ag_api = {
    create      = true
    name        = "${local.lower_name}-ag-api"
    description = "CloudFront--APIGateway--ALB"
    protocol    = "HTTP"
    tags = merge(
      { Project = "${var.name}" },
      var.common_tags
    )
  }
  ag_integration = {
    create             = true
    description        = "integration APIGateway to ALB"
    integration_type   = "HTTP_PROXY"
    integration_uri    = module.alb_to_server.alb.listener.arn
    connection_type    = "VPC_LINK"
    integration_method = "POST"
  }
  ag_route = {
    create     = true
    route_keys = ["POST /api/IF0086"]
  }
  ag_vpc_link = {
    create             = true
    name               = "${local.lower_name}-ag-vpclink"
    security_group_ids = [module.vpc.vpc.security_group["APIGateway"].id]
    subnet_ids         = [local.ec2_instance_subnet_id, element(module.vpc.vpc.subnets, var.ec2_instance_subnet_num + 1).id]
  }
  ag_stage = {
    create      = true
    name        = "$default"
    auto_deploy = true

    access_log_settings = {
      cloudwatch_log_group_arn = module.cloudwatch.log_group["APIGateway"].arn
      log_format = jsonencode({
        apiId                   = "$context.apiId"
        domainName              = "$context.domainName"
        requestId               = "$context.requestId"
        sourceIp                = "$context.identity.sourceIp"
        requestTime             = "$context.requestTime"
        httpMethod              = "$context.httpMethod"
        path                    = "$context.path"
        protocol                = "$context.protocol"
        responseLength          = "$context.responseLength"
        responseLatency         = "$context.responseLatency"
        status                  = "$context.status"
        stage                   = "$context.stage"
        integrationStatus       = "$context.integrationStatus"
        integrationLatency      = "$context.integration.latency"
        integrationErrorMessage = "$context.integrationErrorMessage"
        errorMessage            = "$context.error.message"
        routeKey                = "$context.routeKey"
      })
    }

    default_route_settings = {
      enable_data_trace       = true
      enable_detailed_metrics = true
      limit_throttling_burst  = 20
      limit_throttling_rate   = 80
    }
  }
}
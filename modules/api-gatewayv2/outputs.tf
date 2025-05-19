output "agv2" {
  description = "The configuration for the API Gateway"
  value = {
    api = {
      id            = try(aws_apigatewayv2_api.this[0].id, null)
      api_endpoint  = try(aws_apigatewayv2_api.this[0].api_endpoint, null)
      arn           = try(aws_apigatewayv2_api.this[0].arn, null)
      execution_arn = try(aws_apigatewayv2_api.this[0].execution_arn, null)
    }
    stage = {
      id            = try(aws_apigatewayv2_stage.this[0].id, null)
      arn           = try(aws_apigatewayv2_stage.this[0].arn, null)
      execution_arn = try(aws_apigatewayv2_stage.this[0].execution_arn, null)
      invoke_url    = try(aws_apigatewayv2_stage.this[0].invoke_url, null)
      domain_name   = replace(try(aws_apigatewayv2_stage.this[0].invoke_url, ""), "/^(wss?|https?)://([^/]*).*/", "$2")
    }
  }
}
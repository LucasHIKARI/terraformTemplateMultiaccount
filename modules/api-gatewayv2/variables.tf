variable "ag_api" {
  description = "To manage the Amazon API Gateway Version 2 API"
  type = object({
    create                       = bool
    name                         = string
    description                  = string
    protocol                     = optional(string, "HTTP")
    disable_execute_api_endpoint = optional(bool)
    version                      = optional(string)
    tags                         = optional(map(string), {})
    cors_config = optional(object({
      allow_credentials = optional(bool)
      allow_headers     = optional(list(string))
      allow_methods     = optional(list(string))
      allow_origins     = optional(list(string))
      expose_headers    = optional(list(string))
      # number of seconds that the browser should cache preflight request results
      max_age = optional(number)
    }))
  })
  default = {
    create      = false
    name        = "default"
    description = "default"
  }

  validation {
    condition     = var.ag_api.create ? length(var.ag_api.name) <= 128 : true
    error_message = "The length of API Gateway name must be less than or equal to 128"
  }

  validation {
    condition     = var.ag_api.create ? contains(["HTTP", "WEBSOCKET"], var.ag_api.protocol) : true
    error_message = "The protocol type for API Gateway must be one of [HTTP, WEBSOCKET]"
  }
}

variable "ag_integration" {
  description = "To integrate the API Gateway to the backend service"
  type = object({
    create           = bool
    description      = string
    integration_type = optional(string, "HTTP_PROXY")
    connection_type  = optional(string, "VPC_LINK")
    # If this field is null and the connection_type is VPC_LINK and ag_vpc_link is created, it will be assigned as the ID of that vpc_link
    connection_id             = optional(string)
    credentials_arn           = optional(string)
    content_handling_strategy = optional(string)
    integration_method        = optional(string)
    integration_subtype       = optional(string)
    integration_uri           = optional(string)
    passthrough_behavior      = optional(string, "WHEN_NO_MATCH")
    payload_format_ver        = optional(string, "1.0")
    request_parameters        = optional(map(string))
    request_templates         = optional(map(string))
    response_parameters = optional(object({
      # 200~599
      status_code = number
      mappings    = map(string)
    }))
    # Websocket APIs 50~29000; HTTP APIs 50~30000
    timeout_milliseconds = optional(number, 20000)
    tls_config = optional(object({
      server_name_to_verify = optional(string)
    }))
  })
  default = {
    create      = false
    description = "default"
  }

  validation {
    condition     = var.ag_integration.create ? var.ag_api.create : true
    error_message = "Creating API Gateway integration requires to create API Gateway API"
  }

  validation {
    condition     = var.ag_integration.create ? contains(["AWS", "AWS_PROXY", "HTTP", "HTTP_PROXY", "MOCK"], var.ag_integration.integration_type) : true
    error_message = "The type of an integration must be one of [AWS, AWS_PROXY, HTTP, HTTP_PROXY, MOCK]"
  }

  validation {
    condition     = var.ag_integration.create ? contains(["INTERNET", "VPC_LINK"], var.ag_integration.connection_type) : true
    error_message = "The connection type must be one of [INTERNET, VPC_LINK]"
  }

  validation {
    condition     = var.ag_integration.create && var.ag_integration.content_handling_strategy != null ? contains(["CONVERT_TO_BINARY", "CONVERT_TO_TEXT"], var.ag_integration.content_handling_strategy) : true
    error_message = "The handle type that converts response payload content must be one of [CONVERT_TO_BINARY, CONVERT_TO_TEXT] "
  }

  validation {
    condition     = var.ag_integration.create && var.ag_integration.integration_type != "MOCK" ? var.ag_integration.integration_method != null : true
    error_message = "Must be specified if integration_type is not the MOCK"
  }

  validation {
    condition     = var.ag_integration.create ? contains(["WHEN_NO_MATCH", "WHEN_NO_TEMPLATES", "NEVER"], var.ag_integration.passthrough_behavior) : true
    error_message = "Invalid value of passthrough_behavior"
  }

  validation {
    condition     = var.ag_integration.create ? contains(["1.0", "2.0"], var.ag_integration.payload_format_ver) : true
    error_message = "Invalid value of payload_format_ver"
  }
}

variable "ag_vpc_link" {
  description = "To configure the API Gateway to access a service in the VPC"
  type = object({
    create             = bool
    name               = string
    security_group_ids = optional(set(string), [])
    subnet_ids         = optional(set(string), [])
    tags               = optional(map(string), {})
  })
  default = {
    create = false
    name   = "default"
  }

  validation {
    condition     = var.ag_vpc_link.create ? length(var.ag_vpc_link.name) <= 128 : true
    error_message = "The length of API Gateway name must be less than or equal to 128"
  }
}

variable "ag_route" {
  description = "To map incoming requests to the current ag_integration"
  type = object({
    create               = bool
    route_keys           = optional(set(string), [])
    api_key_required     = optional(bool)
    authorization_scopes = optional(string)
    # WebSocket APIs
    #   NONE: open access
    #   AWS_IAM: AWS IAM permission
    #   CUSTOM: Lambda authorizer
    # HTTP APIs
    #   NONE: open access
    #   JWT: JSON Web Tokens   
    #   AWS_IAM: AWS IAM permission
    #   CUSTOM: Lambda authorizer
    authorization_type         = optional(string, "NONE")
    model_selection_expression = optional(string)
    operation_name             = optional(string)
    request_models             = optional(string)
    request_parameter = optional(object({
      request_parameter_key = string
      required              = optional(bool, true)
    }))
    route_response_selection_expression = optional(string)
  })
  default = {
    create = false
  }
}

variable "ag_authorizer" {
  description = "To configure the authorization for the current ag_integration"
  type = object({
    create = bool
    # Lambda function: REQUEST
    # HTTP APIs: JWT
    authorizer_type = optional(string, "JWT")
  })
  default = {
    create = false
  }
}

variable "ag_stage" {
  description = "To define stage resource for the current API Gateway"
  type = object({
    create      = bool
    name        = optional(string, "$default")
    auto_deploy = optional(bool, true)
    access_log_settings = optional(object({
      cloudwatch_log_group_arn = string
      log_format               = string
    }))
    default_route_settings = optional(object({
      # Supported only for WebSocket APIs
      # enable_data_trace       = optional(bool, false)
      enable_detailed_metrics = optional(bool, false)
      # ERROR, INFO, OFF
      # Supported only for WebSocket APIs
      log_level              = optional(string, "INFO")
      limit_throttling_burst = optional(number)
      limit_throttling_rate  = optional(number)
    }))
    route_settings = optional(set(object({
      route_key = string
      # Supported only for WebSocket APIs
      # enable_data_trace       = optional(bool, false)
      enable_detailed_metrics = optional(bool, false)
      # ERROR, INFO, OFF
      # Supported only for WebSocket APIs
      log_level              = optional(string, "INFO")
      limit_throttling_burst = optional(number)
      limit_throttling_rate  = optional(number)
    })), [])
  })
  default = {
    create = false
  }
}
## API Gateway
resource "aws_api_gateway_rest_api" "this" {
  name = "${local.project_name}-api-${var.environment}"
  tags = {
    Environment = var.environment
    Project     = local.project_name
  }
}

# API Gateway resources and methods for both create and redirect URLs APIs
resource "aws_api_gateway_resource" "this" {
  for_each = local.apis
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_method" "this" {
  for_each = local.apis
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.this[each.key].id
  http_method   = each.value.http_method
  authorization = each.value.authorization
}

resource "aws_api_gateway_integration" "this" {
  for_each = local.apis
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this[each.key].id
  http_method = aws_api_gateway_method.this[each.key].http_method
  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.this[each.key].invoke_arn
}

resource "aws_api_gateway_deployment" "this" {
  
  rest_api_id = aws_api_gateway_rest_api.this.id  
  depends_on = [
    aws_api_gateway_method.this,
    aws_api_gateway_integration.this
  ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = var.environment
  deployment_id = aws_api_gateway_deployment.this.id

  tags = {
    Environment = var.environment
    Project     = local.project_name
  }
}

resource "aws_api_gateway_request_validator" "this" {
  name                        = "${local.project_name}-validator-${var.environment}"
  rest_api_id                 = aws_api_gateway_rest_api.this.id
  validate_request_body       = true
  validate_request_parameters = true
}

# Add throttling to the stage
resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    throttling_rate_limit  = 100
    throttling_burst_limit = 200
    logging_level         = "ERROR"
    data_trace_enabled    = false
    metrics_enabled       = true
  }
}
## API Gateway
resource "aws_api_gateway_rest_api" "this" {
  name = "${local.project_name}-api-${var.environment}"
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
  integration_http_method = each.value.http_method
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.this[each.key].invoke_arn
}
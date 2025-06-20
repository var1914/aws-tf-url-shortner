## LAMBDA
# Lambda function for creating and redirecting short URLs
resource "aws_lambda_function" "this" {
  for_each = local.apis
  filename         = each.key.filename
  function_name    = each.key.function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = each.key.handler
  runtime         = "nodejs22.x"
  timeout         = each.key.timeout

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.this.name
    }
  }
  tags = {
    Environment = var.environment
    Project     = local.project_name
  }
}

## DynamoDB
# DynamoDB table for storing short URLs
resource "aws_dynamodb_table" "this" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "short_id"

  attribute {
    name = "short_id"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Project     = local.project_name
  }
}

## IAM 
# IAM role for Lambda functions
resource "aws_iam_role" "this" {
  name = "${local.project_name}-lambda-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the basic execution role policy and custom DynamoDB access policy to the Lambda role
resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${local.project_name}-dynamodb-access-${var.environment}"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.this.arn
      }
    ]
  })
}

## API Gateway
resource "aws_api_gateway_rest_api" "this" {
  name = "${local.project_name}-api-${var.environment}"
}

# API Gateway resources and methods for both create and redirect URLs APIs
resource "aws_api_gateway_resource" "this" {
  for_each = local.apis
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.key.path_part
}

resource "aws_api_gateway_method" "this" {
  for_each = local.apis
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.this[each.key].id
  http_method   = each.key.http_method
  authorization = each.key.authorization
}

resource "aws_api_gateway_integration" "this" {
  for_each = local.apis
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.this[each.key].id
  http_method = aws_api_gateway_method.this[each.key].http_method
  integration_http_method = each.key.http_method
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.this[each.key].invoke_arn
}
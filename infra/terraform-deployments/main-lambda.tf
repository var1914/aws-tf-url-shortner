## LAMBDA
# Lambda function for creating and redirecting short URLs
resource "aws_lambda_function" "this" {
  for_each = local.apis
  filename         = each.value.filename
  function_name    = each.value.function_name
  role            = aws_iam_role.this.arn
  handler         = each.value.handler
  runtime         = "nodejs22.x"
  timeout         = each.value.timeout

  environment {
    variables = each.value.environment
  }
  tags = {
    Environment = var.environment
    Project     = local.project_name
  }
}

resource "aws_lambda_permission" "api_gw" {
  for_each = local.apis
  
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
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

resource "aws_iam_role_policy" "lambda_logging" {
  name = "${local.project_name}-lambda-logging-${var.environment}"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}
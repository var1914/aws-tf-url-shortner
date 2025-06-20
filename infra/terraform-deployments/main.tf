

# Lambda function for creating and redirecting short URLs
resource "aws_lambda_function" "this" {
  for_each = local.lambda
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
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
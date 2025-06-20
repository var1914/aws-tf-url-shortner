# URL Shortener Infrastructure Configuration
# 
# Architecture:
# - API Gateway: Public endpoints for create/redirect
# - Lambda: Serverless compute for business logic  
# - DynamoDB: NoSQL storage with pay-per-request billing
# - CloudWatch: Monitoring with SNS alerting
#
# Endpoints:
# - POST /shorten: Create short URL (requires API key)
# - GET /{id}: Redirect to original URL (public)
locals {
  project_name = "url-shortener"
  table_name = "${local.project_name}-${var.environment}"
  apis = {
    create_url = {
        filename = "${path.root}/../../create-url.zip"
        function_name    = "${local.project_name}-create-${var.environment}"
        handler         = "create-url.handler"
        timeout         = 10
        path_part = "shorten"
        http_method = "POST"
        authorization = "NONE"
        environment = {
          TABLE_NAME = local.table_name
          VALID_API_KEYS = var.api_keys
        }
    }
    redirect_url = {
        filename         = "${path.root}/../../redirect-url.zip"
        function_name    = "${local.project_name}-redirect-${var.environment}"
        handler         = "redirect-url.handler"
        timeout         = 5
        path_part = "{id}"
        http_method = "GET"
        authorization = "NONE"
        environment = {
          TABLE_NAME = local.table_name
        }
    }
  }

}
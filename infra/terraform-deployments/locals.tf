locals {
  project_name = "url-shortener"
  table_name = "${local.project_name}-${var.environment}"
  lambda = {
    create-url = {
      filename = "create-url.zip"
      function_name    = "${local.project_name}-create-${var.environment}"
      handler         = "create-url.handler"
      timeout         = 10
    }
    redirect-url = {
      filename         = "redirect.zip"
      function_name    = "${local.project_name}-redirect-${var.environment}"
      handler         = "redirect-url.handler"
      timeout         = 5
    }
  }
}
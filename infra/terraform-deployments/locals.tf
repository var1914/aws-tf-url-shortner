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
        authorization = "AWS_IAM"
    }
    redirect_url = {
        filename         = "${path.root}/../../redirect.zip"
        function_name    = "${local.project_name}-redirect-${var.environment}"
        handler         = "redirect-url.handler"
        timeout         = 5
        path_part = "{id}"
        http_method = "GET"
        authorization = "NONE"
    }
  }

}
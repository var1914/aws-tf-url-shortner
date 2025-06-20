provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-varun-blogs"
    key            = "tf-state.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
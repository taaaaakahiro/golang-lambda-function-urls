terraform {
  required_version = ">= 0.11"
  backend "s3" {
    bucket = "golang-aws-lambda"
    key    = "lambda_function_urls/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}
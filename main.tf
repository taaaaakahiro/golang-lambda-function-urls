################################################################################
# Lambda(Server)                                                               #
################################################################################
data "archive_file" "server" {
  type        = "zip"
  source_dir  = "./artifact/server"
  output_path = "./outputs/lambda_server_function.zip"
}

resource "aws_lambda_function" "server" {
  depends_on = [
    aws_cloudwatch_log_group.lambda_server,
  ]

  function_name    = local.lambda_server_function_name
  filename         = data.archive_file.server.output_path
  role             = aws_iam_role.lambda.arn
  handler          = "server"
  source_code_hash = data.archive_file.server.output_base64sha256
  runtime          = "go1.x"

  memory_size = 128
  timeout     = 30
}

resource "aws_lambda_function_url" "server" {
  function_name      = aws_lambda_function.server.function_name
  authorization_type = "AWS_IAM"
}

resource "aws_lambda_permission" "allow_function_url_auth_type_iam" {
  statement_id  = "FunctionURLAllowLambdaIAMAccess"
  action        = "lambda:InvokeFunctionUrl"
  function_name = aws_lambda_function.server.function_name
  principal     = aws_iam_role.lambda.arn
  function_url_auth_type = "AWS_IAM"
}

resource "aws_cloudwatch_log_group" "lambda_server" {
  name              = "/aws/lambda/${local.lambda_server_function_name}"
  retention_in_days = 3
}

################################################################################
# Lambda(Proxy)                                                                #
################################################################################
data "archive_file" "proxy" {
  type        = "zip"
  source_dir  = "./artifact/proxy"
  output_path = "./outputs/lambda_proxy_function.zip"
}

resource "aws_lambda_function" "proxy" {
  depends_on = [
    aws_cloudwatch_log_group.lambda_proxy,
  ]

  function_name    = local.lambda_proxy_function_name
  filename         = data.archive_file.proxy.output_path
  role             = aws_iam_role.lambda.arn
  handler          = "proxy"
  source_code_hash = data.archive_file.proxy.output_base64sha256
  runtime          = "go1.x"

  memory_size = 128
  timeout     = 30

  environment {
    variables = {
      LAMBDA_SERVER_URL = aws_lambda_function_url.server.function_url
    }
  }
}

resource "aws_lambda_function_url" "proxy" {
  function_name      = aws_lambda_function.proxy.function_name
  authorization_type = "NONE"
}

resource "aws_cloudwatch_log_group" "lambda_proxy" {
  name              = "/aws/lambda/${local.lambda_proxy_function_name}"
  retention_in_days = 3
}

################################################################################
# IAM                                                                          #
################################################################################
resource "aws_iam_role" "lambda" {
  name               = local.iam_role_name_lambda
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role_policy" "lambda_custom" {
  name   = local.iam_policy_name_lambda
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_service_account_custom.json
}

data "aws_iam_policy_document" "lambda_service_account_custom" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "*",
    ]
  }
}

################################################################################
# Outputs                                                                      #
################################################################################
output "lambda_server_function_url" {
  value = aws_lambda_function_url.server.function_url
}

output "lambda_proxy_function_url" {
  value = aws_lambda_function_url.proxy.function_url
}
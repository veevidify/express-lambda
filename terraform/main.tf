// == tf == //
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = " ~> 3.27"
    }
  }

  required_version = " >= 0.14.9"

  backend "s3" {
  }
}

provider "aws" {
  profile = "default"
  region  = "ap-southeast-2"
}

// == end tf == //

// iam resource assume role
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals = {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

// lambda function iam role
resource "aws_iam_role" "simple_lambda_iam_role" {
  name               = var.lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}


// create the lambda function
resource "aws_lambda_function" "simple_lambda" {
  filename         = "index.zip"
  function_name    = var.lambda_function_name
  role             = aws_iam_role.simple_lambda_iam_role.arn
  handler          = "index.handler"
  runtime          = var.runtime
  source_code_hash = filebase64sha256("index.zip")
  environment {
    variables = {
      env = var.environment
    }
  }
}

// allow lambda invocation
resource "aws_lambda_permission" "allow_invoke_lambda" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.simple_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.simple_bucket.id}"
}

// log group
resource "aws_cloudwatch_log_group" "simple_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 1
}

// iam policy for lambda logging
data "aws_iam_policy_document" "lambda_logging_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
    effect    = "Allow"
  }
}

// cloudwatch logging policy
resource "aws_iam_policy" "lambda_logging_policy" {
  name        = var.lambda_logging_iam_policy_name
  path        = "/"
  description = "IAM policy for lambda function logging"
  policy      = data.aws_iam_policy_document.lambda_logging_policy.json
}

// attach policy & role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.simple_lambda_iam_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

// api gateway
resource "aws_apigatewayv2_api" "simple_lambda_api_gw" {
  name          = "simple_lambda_api_gw"
  protocol_type = "HTTP"
}

// api stage
resource "aws_apigatewayv2_stage" "simple_lambda_stage" {
  api_id = aws_apigatewayv2_api.simple_lambda_api_gw.id

  name        = "simple_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.simple_log_group.arn

    format = jsonencode({
      requestId                 = "$context.requestId"
      sourceIp                  = "$context.identity.sourceIp"
      requestTime               = "$context.requestTime"
      protocol                  = "$context.protocol"
      httpMethod                = "$context.httpMethod"
      resourcePath              = "$context.resourcePath"
      routeKey                  = "$context.routeKey"
      status                    = "$context.status"
      responseLength            = "$context.responseLength"
      integrationErrorMessage.g = "$context.req"
    })
  }
}

// integrate with lambda
resource "aws_apigatewayv2_integration" "simple_lambda_integration" {
  api_id = aws_apigatewayv2_api.simple_lambda_api_gw.id

  integration_uri    = aws_lambda_function.simple_lambda.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "simple_lambda_main" {
  api_id = aws_apigatewayv2_api.simple_lambda_api_gw.id

  route_key = "GET /main"
  target    = "integrations/${aws_apigatewayv2_integration.simple_lambda_integration.id}"
}

resource "aws_lambda_permission" "simple_lambda_api_gw_invocation" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.simple_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.simple_lambda_api_gw.execution_arn}/*/**"
}

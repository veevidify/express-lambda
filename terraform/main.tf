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

// == iam role for this lambda to manage access to other aws resources == //
// policy document
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

// creating the iam role resource
resource "aws_iam_role" "simple_lambda_iam_role" {
  name               = var.lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}


// == create the function == //
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

// log group
resource "aws_cloudwatch_log_group" "simple_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 1
}

// == iam policy to allow lambda iam role to write logs to cw
// policy document
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

// iam policy
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


// == api gateway == //
// create the api rest api resource
// will contain other api gw objects later
resource "aws_api_gateway_rest_api" "api_gw_rest" {
  name = var.api_gw_name
}

// proxy matching request paths
resource "aws_api_gateway_resource" "api_gw_proxy" {
  rest_api_id = aws_api_gateway_rest_api.api_gw_rest.id
  parent_id   = aws_api_gateway_rest_api.api_gw_rest.root_resource_id
  path_part   = "{proxy+}"
}

// allow http methods
resource "aws_api_gateway_method" "api_gw_proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gw_rest.id
  resource_id   = aws_api_gateway_resource.api_gw_proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

// integrate this gateway with lambda
// aws_proxy lets api_gw invoke an aws resource
resource "aws_api_gateway_integration" "lambda_api_gw_integration" {
  rest_api_id = aws_api_gateway_rest_api.api_gw_rest.id
  # below same as aws_api_gateway_resource.api_gw_proxy.id
  resource_id = aws_api_gateway_method.api_gw_proxy_method.resource_id
  http_method = aws_api_gateway_method.api_gw_proxy_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.simple_lambda.invoke_arn
}

// must have root "/"" before building sub-routes
resource "aws_api_gateway_method" "api_gw_proxy_root_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gw_rest.id
  resource_id   = aws_api_gateway_rest_api.api_gw_rest.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_api_gw_root_integration" {
  rest_api_id = aws_api_gateway_rest_api.api_gw_rest.id
  # below same as aws_api_gateway_rest_api.api_gw_rest.root_resource_id
  resource_id = aws_api_gateway_method.api_gw_proxy_root_method.resource_id
  http_method = aws_api_gateway_method.api_gw_proxy_root_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.simple_lambda.invoke_arn
}

// deploy the api gateway on the internet
// activate & expose the api gateway endpoint for testing
resource "aws_api_gateway_deployment" "api_gw_deploy" {
  depends_on = [
    aws_api_gateway_integration.lambda_api_gw_integration,
    aws_api_gateway_integration.lambda_api_gw_root_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.api_gw_rest.id
  stage_name  = "test"
}


// == finally allow access from api gw to lambda == //
// give permission to api gw to invoke function
resource "aws_lambda_permission" "api_gw_invoke_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.simple_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  // allow mapping/passing any resources within api_gw_rest to lambda function
  source_arn = "${aws_api_gateway_rest_api.api_gw_rest.execution_arn}/*/*"
}

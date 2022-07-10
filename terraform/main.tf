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
    bucket = var.backend_state
    key    = "apps/s3/terraform.tfstate"
    region = "ap-southeast-2"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
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

resource "aws_iam_role" "simple_lambda_iam" {
  name               = var.lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}


// set up lambda
resource "aws_lambda_function" "simple_lambda" {
  filename         = "index.zip"
  function_name    = var.lambda_function_name
  role             = aws_iam_role.simple_lambda_iam.arn
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

resource "aws_iam_policy" "lambda_logging" {
  name        = var.lambda_logging_iam_policy_name
  path        = "/"
  description = "IAM policy for lambda function logging"
  policy      = data.aws_iam_policy_document.lambda_logging_policy.json
}

// attach policy & role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.simple_lambda_iam.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

// TODO: api gateway, pub subnet, security group, policy, attach, eip

//

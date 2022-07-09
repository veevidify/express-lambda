terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = " ~> 3.27"
    }
  }

  required_version = " >= 0.14.9"

  backend "s3" {
    bucket = "some-backend"
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

// == //

// iam resource: role
resource "aws_iam_role" "simple_lambda_iam" {
  name = var.lambda_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

// iam resource: role policy
resource "aws_iam_role_policy" "revoke_keys_role_policy" {
  name = var.lambda_iam_policy_name
  role = aws_iam_role.simple_lambda_iam.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["s3:*"],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
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

// TODO: api gateway, pub subnet, security group, policy, attach, eip

//

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
resource "aws_iam_policy" "lambda_logging" {
  name        = var.lambda_logging_iam_policy_name
  path        = "/"
  description = "IAM policy for lambda function logging"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

// attach policy & role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.simple_lambda_iam.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

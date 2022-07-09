variable "lambda_function_name" {
  default = "simple-lambda"
}

variable "runtime" {
  default = "nodejs16.x"
}

variable "timeout" {
  default = "100000"
}

variable "lambda_role_name" {
  default = "simple-lambda-iam-role"
}

variable "lambda_iam_policy_name" {
  default = "simple-lambda-iam-policy"
}

variable "bucket_name" {
  default = "simple-bucket"
}

variable "environment" {
  default = "dev"
}

variable "lambda_logging_iam_policy_name" {
  default = "simple_lambda_logging"
}

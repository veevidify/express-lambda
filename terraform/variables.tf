variable "backend_dynamodb_table" {
  default = "terraform-up-and-running-locks"
}

variable "backend_bucket_name" {
  default = "simple-bucket"
}

variable "backend_bucket_key" {
  default = "apps/s3/terraform.tfstate"
}

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

variable "environment" {
  default = "dev"
}

variable "lambda_logging_iam_policy_name" {
  default = "simple-lambda-logging-policy"
}

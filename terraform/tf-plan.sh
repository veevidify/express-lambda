#!/bin/bash

# Wrapper to invoke terraform

# injecting environment variables into terraform variables to init/apply
# these environment variables are injected into the container by docker-compose

echo "..Running init"
terraform init \
    -backend-config="bucket=${TERRAFORM_BACKEND_BUCKET}" \
    -backend-config="key=${TERRAFORM_BACKEND_KEY}" \
    -backend-config="dynamodb_table=${TERRAFORM_BACKEND_TABLE}" \
    -backend-config="region=ap-southeast-2" \
    -backend-config="encrypt=true"

echo "..Plan"
terraform plan \
    -var="lambda_function_name=${TERRAFORM_AWS_FUNCTION_NAME}" \
    -var="lambda_role_name=${TERRAFORM_AWS_FUNCTION_ROLE_NAME}" \
    -var="lambda_iam_policy_name=${TERRAFORM_AWS_FUNCITON_POLICY_NAME}" \
    -var="lambda_logging_iam_policy_name=${TERRAFORM_AWS_LOGGING_POLICY_NAME}" \
    -var="environment=stage"

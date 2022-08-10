#!/bin/bash

# Wrapper to invoke terraform

# injecting environment variables into terraform variables to init/apply
# these environment variables are injected into the container by docker-compose

cd ../terraform

terraform init \
    -backend-config="bucket=${TERRAFORM_BACKEND_BUCKET}" \
    -backend-config="key=${TERRAFORM_BACKEND_KEY}" \
    -backend-config="dynamodb_table=${TERRAFORM_BACKEND_TABLE}" \
    -backend-config="region=ap-southeast-2" \
    -backend-config="encrypt=true"

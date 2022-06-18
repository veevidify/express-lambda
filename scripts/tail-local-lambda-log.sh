#!/bin/sh

set -e
export AWS_DEFAULT_REGION=ap-southeast-2
export AWS_ACCESS_KEY_ID=local
export AWS_SECRET_ACCESS_KEY=local

aws --endpoint-url=http://localhost:4566 \
  logs tail '/aws/lambda/simple-lambda' --follow

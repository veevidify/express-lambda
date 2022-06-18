#!bin/sh

set -e
export AWS_DEFAULT_REGION=ap-southeast-2
export AWS_ACCESS_KEY_ID=local
export AWS_SECRET_ACCESS_KEY=local

echo "== package the lambda"
npm run build
echo "<=="

echo "== create the lambda function"
aws --endpoint-url=http://localhost:4566 --region=ap-southeast-2 \
  lambda create-function --function-name simple-lambda \
  --zip-file fileb://dist/index.zip \
  --handler index.handler --runtime nodejs16.x \
  --role arn:aws:iam::000000000000:role/lambda-role | cat
echo "<=="

echo "create the s3 bucket"
aws --endpoint-url=http://localhost:4566 --region=ap-southeast-2 \
  s3 mb s3://simple-bucket
echo "<=="

echo "attach the trigger"
aws --endpoint-url=http://localhost:4566 --region=ap-southeast-2 \
  s3api put-bucket-notification-configuration --bucket simple-bucket \
  --notification-configuration file://scripts/event-trigger-local-config.json
echo "<=="

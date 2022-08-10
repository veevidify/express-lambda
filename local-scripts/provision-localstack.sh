#!bin/sh

set -e
export AWS_DEFAULT_REGION=ap-southeast-2
export AWS_ACCESS_KEY_ID=local
export AWS_SECRET_ACCESS_KEY=local
export FUNCTION_NAME=express-lambda
export API_NAME=express-lambda-api-gw

echo "== package the lambda"
npm install && npm run build
echo "<=="

echo "== create the lambda function"
aws --endpoint-url=http://localhost:4566 --region=ap-southeast-2 \
  lambda create-function \
  --function-name $FUNCTION_NAME \
  --zip-file fileb://dist/index.zip \
  --handler index.handler --runtime nodejs16.x \
  --role arn:aws:iam::000000000000:role/lambda-role | cat
echo "<=="

LAMBDA_ARN=$(aws --endpoint-url=http://localhost:4566 --region=ap-southeast-2 lambda list-functions --query "Functions[?FunctionName==\`${FUNCTION_NAME}\`].FunctionArn" --output text)

echo "== create rest-api"
aws --endpoint-url=http://localhost:4566 --region=ap-southeast-2 \
  apigateway create-rest-api \
  --name ${API_NAME} | cat
echo "<=="

API_ID=$(aws --endpoint-url=http://localhost:4566 --region=ap-southeast-2 apigateway get-rest-apis --query "items[?name==\`${API_NAME}\`].id" --output text)
PARENT_RESOURCE_ID=$(aws --endpoint-url=http://localhost:4566 --region=ap-southeast-2 apigateway get-resources --rest-api-id ${API_ID} --query 'items[?path==`/`].id' --output text)

echo "== create api gw resource"
aws --endpoint-url=http://localhost:4566 --region=ap-southeast-2 \
  apigateway create-resource \
  --rest-api-id ${API_ID} \
  --parent-id ${PARENT_RESOURCE_ID} \
  --path-part "{someId}" | cat
echo "<=="

RESOURCE_ID=$(aws --endpoint-url=http://localhost:4566 --region=ap-southeast-2 apigateway get-resources --rest-api-id ${API_ID} --query 'items[?path==`/{someId}`].id' --output text)

echo "== define http method"
aws --endpoint-url=http://localhost:4566 --region=ap-southeast-2 \
  apigateway put-method \
  --rest-api-id ${API_ID} \
  --resource-id ${RESOURCE_ID} \
  --http-method GET \
  --request-parameters "method.request.path.someId=true" \
  --authorization-type "NONE" | cat
echo "<=="

echo "== integrate with lambda"
aws --endpoint-url=http://localhost:4566 --region=ap-southeast-2 \
  apigateway put-integration \
  --rest-api-id ${API_ID} \
  --resource-id ${RESOURCE_ID} \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:ap-southeast-2:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations \
  --passthrough-behavior WHEN_NO_MATCH | cat
echo "<=="

echo "== deployment"
aws --endpoint-url=http://localhost:4566 --region=ap-southeast-2 \
  apigateway create-deployment \
  --rest-api-id ${API_ID} \
  --stage-name local | cat
echo "<=="

echo "== Provision localstack successful! =="
echo "Details:"
echo "LAMBDA_ARN: ${LAMBDA_ARN}"
echo "RESOURCE_ID: ${RESOURCE_ID}"
echo "API_NAME: ${API_NAME}"
echo "API_ID: ${API_ID}"
echo "To Test invocation: $ curl localhost:4566/restapis/${API_ID}/local/_user_request_/main"

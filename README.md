## Contents.
- [Contents.](#contents)
- [1. Simple lambda overview](#1-simple-lambda-overview)
- [2. Local](#2-local)
- [3. Use terraform to provision AWS resources](#3-use-terraform-to-provision-aws-resources)

---
## 1. Simple lambda overview
- AWS lambda triggered by S3 put events
- Test locally with localstack docker container

---
## 2. Local
- Make sure `aws-cli` v2 is installed
- Start localstack
```sh
$
docker-compose up -d && docker-compose logs -f
```
output:
```console
Attaching to simple-lambda_localstack_1
localstack_1  | Waiting for all LocalStack services to be ready
localstack_1  | 2022-06-18 01:36:01,464 CRIT Supervisor is running as root.  Privileges were not dropped because no user is specified in the config file.  If you intend to run as root, you can set user=root in the config file to avoid this message.
...
```
- Create resources within localstack
```sh
$
bash scripts/provision-localstack.sh
```
output:
```console
== package the lambda

> simple-lambda@1.0.0 prebuild
> rm -rf dist


> simple-lambda@1.0.0 build
> tsc && esbuild src/index.ts --bundle --minify --sourcemap --platform=node --target=es2020 --outfile=dist/index.js
...
```
- Tail lambda logs with `aws-cli`
```sh
$
bash scripts/tail-local-lambda-log.sh
```
output:
```console
2022-06-18T02:47:56.165000+00:00 2022/06/18/[LATEST]f751cd25 START f16e4581-04fc-49e4-8619-8bcbc83b4ddb: Lambda arn:aws:lambda:ap-southeast-2:000000000000:function:simple-lambda started via "local" executor ...
...
```
- To test the trigger, run integration test
```sh
$
npm run test
```
output:
```console
> simple-lambda@1.0.0 test
> AWS_ACCESS_KEY_ID=local AWS_SECRET_ACCESS_KEY=local jest

 PASS  src/index.integration.test.ts
  testing lambda with localstack
    lambda handler
      ✓ should listen & react to s3 put event (45 ms)
```
```
2022-06-18T02:47:56.166000+00:00 2022/06/18/[LATEST]f751cd25 ==> Event:  {
2022-06-18T02:47:56.167000+00:00 2022/06/18/[LATEST]f751cd25   "Records": [
2022-06-18T02:47:56.167000+00:00 2022/06/18/[LATEST]f751cd25     {
2022-06-18T02:47:56.168000+00:00 2022/06/18/[LATEST]f751cd25       "eventVersion": "2.1",
2022-06-18T02:47:56.169000+00:00 2022/06/18/[LATEST]f751cd25       "eventSource": "aws:s3",
...
```
- No tear down scripts. Just destroy the container:
```sh
$
docker-compose down -v
```
output:
```console
Stopping simple-lambda_localstack_1 ... done
Removing simple-lambda_localstack_1 ... done
Removing network simple-lambda_default
```

---
## 3. Use terraform to provision AWS resources
- First create the variables. Note that bucket name needs to be unique:
```sh
$
cd terraform
cp variables.tf.example variables.tf
```
- Then change the values
- Also change the bucket name for tf backend state:
```sh
  backend "s3" {
    bucket = "yours"
    ...
```
- init, plan & apply
```sh
$
terraform init
```
output:
```console
Initializing the backend...
Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v3.75.2

Terraform has been successfully initialized!
...
```
```sh
$
terraform plan
```
output:
```console
Terraform used the selected providers to generate the
following execution plan. Resource actions are indicated
with the following symbols:
...

Plan: 10 to add, 0 to change, 0 to destroy.
...
```
```sh
$
terraform apply
```
output:
```console
Terraform used the selected providers to generate the
following execution plan. Resource actions are indicated
with the following symbols:
...

Plan: 10 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```
- Yes and enter

output:
```console
aws_cloudwatch_log_group.simple_log_group: Creating...
aws_iam_policy.lambda_logging: Creating...
aws_iam_role.simple_lambda_iam: Creating...
aws_s3_bucket.simple_bucket: Creating...
...

Apply complete! Resources: 10 added, 0 changed, 0 destroyed.
```
- Tear down
```sh
$
terraform destroy
```
output:
```console
aws_iam_policy.lambda_logging: Refreshing state...
...

Plan: 0 to add, 0 to change, 10 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value:
```
- Yes and enter

output:
```console
aws_iam_role_policy.revoke_keys_role_policy: Destroying...
...

Destroy complete! Resources: 10 destroyed.
```

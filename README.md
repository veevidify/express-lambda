## Contents.
- [Contents.](#contents)
- [1. Simple lambda overview](#1-simple-lambda-overview)
- [2. Development](#2-development)
- [3. Local](#3-local)
- [4. Use terraform to provision AWS resources](#4-use-terraform-to-provision-aws-resources)

---
## 1. Simple lambda overview
- AWS lambda triggered by S3 put events
- Test locally with localstack docker container

---
## 2. Development
- Clone & install dependencies:
```sh
$
git clone git@github.com:veevidify/express-lambda.git
cd express-lambda
npm clean-install
```
- Start local version of the express instance to test functionalities:
```sh
$
npm run dev
```
output:
```console
> simple-lambda@1.0.0 dev
> ts-node src/express-entrypoint.ts

Application listening on port 8080 ...
```

---
## 3. Local
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
## 4. Use terraform to provision AWS resources
- Terraform actions are wrapped within the `tf-env` service container in compose stack & bash scripts within `./terraform`.

- First enter the container:

```sh
$
docker-compose run tf-env
```
- In the container's shell, use the pre-written scripts for `plan` & `apply`:
```sh
/app/terraform $ sh tf-plan.sh
```
output:
```console
..Running init

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v3.75.2

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
..Plan
data.aws_iam_policy_document.lambda_logging_policy: Reading...

...

Plan: 13 to add, 0 to change, 0 to destroy.
```
- Review. Once ready, apply (enter yes at prompt):
```sh
/app/terraform $ sh tf-apply.sh
```
output:
```console
..Running init

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v3.75.2

Terraform has been successfully initialized!

...

Plan: 13 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

```console
aws_cloudwatch_log_group.simple_log_group: Creating...
aws_iam_policy.lambda_logging_policy: Creating...

...

aws_api_gateway_deployment.api_gw_deploy: Creating...
aws_api_gateway_deployment.api_gw_deploy: Creation complete after 1s [id=wc6nag]

Apply complete! Resources: 13 added, 0 changed, 0 destroyed.
```

- Test the stack. Use the url provided by aws (WIP), replace `/{proxy+}` with `/main` to observe the output.
- Once all is done, tear down (enter yes at prompt):
```sh
/app/terraform $ terraform destroy
```
output:
```console
data.aws_iam_policy_document.lambda_logging_policy: Reading...
aws_cloudwatch_log_group.simple_log_group: Refreshing state... [id=/aws/lambda/simple-lambda]
data.aws_iam_policy_document.assume_role_policy: Reading...

...

Plan: 0 to add, 0 to change, 13 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
```

```console
aws_iam_role_policy_attachment.lambda_logs: Destroying... [id=simple-lambda-iam-role-20221008034306570000000001]
aws_lambda_permission.api_gw_invoke_lambda: Destroying... [id=AllowAPIGatewayInvoke]

...

aws_iam_policy.lambda_logging_policy: Destruction complete after 2s
aws_iam_role.simple_lambda_iam_role: Destruction complete after 4s

Destroy complete! Resources: 13 destroyed.
```

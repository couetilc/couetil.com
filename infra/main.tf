# 1. create ECR private repository
# 2. Create Lambda function
# 3. Create Api gateway
# 4. Create Cloudfront Distribution
# 5. DNS records?

terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = "~> 5.0"
		}
	}

	backend "s3" {
		bucket = "tf.couetil.com"
		key = "terraform.tfstate"
		region = "us-east-1"
		use_lockfile = true
	}
}

provider "aws" {
	region = "us-east-1"
}

resource "aws_s3_bucket" "tf_couetil_com" {
	bucket = "tf.couetil.com"
	tags = {
		Domain = "couetil.com"
		Service = "tf.couetil.com"
	}
}

resource "aws_s3_bucket_versioning" "tf_couetil_com" {
	bucket = aws_s3_bucket.tf_couetil_com.id
	versioning_configuration {
		status = "Enabled"
	}
}

resource "aws_ecr_repository" "www" {
	name = "www.couetil.com"
	image_tag_mutability = "MUTABLE"
}

resource "aws_iam_role" "lambda_exec" {
	name = "www.couetil.com-exec-role"
	assume_role_policy = <<EOF
	{
		"Version": "2012-10-17",
		"Statement": [{
			"Effect": "Allow",
			"Principal": { "Service": "lambda.amazonaws.com" },
			"Action": "sts:AssumeRole"
		}]
	}
	EOF
}

# allow writing logs to cloudwatch
resource "aws_iam_role_policy_attachment" "cw_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# allow pulling images from ECR
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_lambda_function" "www" {
	function_name = "www"
	package_type = "Image"
	image_uri = "${aws_ecr_repository.www.repository_url}:latest"
	role = aws_iam_role.lambda_exec.arn
	timeout = 30
}

resource "aws_apigatewayv2_api" "www" {
  name          = "www"
  protocol_type = "HTTP"
}

resource "aws_lambda_permission" "www" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.www.function_name
  principal     = "apigateway.amazonaws.com"
  # This allows any route on the HTTP API to invoke the function
  source_arn    = "${aws_apigatewayv2_api.www.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "www" {
  api_id                 = aws_apigatewayv2_api.www.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.www.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "www" {
  api_id    = aws_apigatewayv2_api.www.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.www.id}"
}

resource "aws_apigatewayv2_stage" "www" {
  api_id      = aws_apigatewayv2_api.www.id
  name        = "$default"
  auto_deploy = true
}

output "www_invoke_url" {
  description = "Public invoke URL for the HTTP API"
  value       = aws_apigatewayv2_stage.www.invoke_url
}

resource "aws_secretsmanager_secret" "account_id" {
  name        = "www/aws-account-id"
  description = "The AWS account ID used by www"
}

data "aws_secretsmanager_secret_version" "account_id" {
  secret_id = aws_secretsmanager_secret.account_id.id
}

locals {
  aws_account_id = data.aws_secretsmanager_secret_version.account_id.secret_string
}

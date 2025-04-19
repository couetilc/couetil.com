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
	default_tags {
		tags = {
			service = "www.couetil.com"
		}
	}
}

resource "aws_s3_bucket" "tf_couetil_com" {
	bucket = "tf.couetil.com"
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

# TODO: does this already exist as a default somewhere in AWS IAM? Or can I switch this to a data block, like below for apigateway assume role? What is the difference between data and resource for iam roles?
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
  access_log_settings {
	destination_arn = aws_cloudwatch_log_group.www_apigateway.arn
	format = "$context.extendedRequestId $context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId"
  }
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
  www_origin_id = "WwwApiGatewayOrigin"
}


resource "aws_cloudfront_distribution" "www" {
  enabled             = true
  default_root_object = ""   # no index document; we pass through every request
  is_ipv6_enabled = true
  http_version = "http2"

  origin {
    domain_name = replace( aws_apigatewayv2_stage.www.invoke_url, "/^https?://|/$/", "")
    origin_id   = local.www_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 30
      origin_keepalive_timeout = 5
    }
  }
  
  # default_cache_behavior {
  #   target_origin_id       = "APIGatewayOrigin"
  #   viewer_protocol_policy = "redirect-to-https"
  #   allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
  #   cached_methods         = ["GET", "HEAD"]
  #   compress               = true
  #
  #   # forward everything your Lambda/API needs
  #   forwarded_values {
  #     query_string = true
  #     headers      = ["Authorization", "Content-Type", "Accept", "Origin"]
  #     cookies {
  #       forward = "all"
  #     }
  #   }
  # }

  # NOTE: for future updates, the CachingOptimized
  # (https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html)
  # seems like a good cache policy, it minimizes cache key size to increase
  # cache misses and I think it also compresses response bodies.
  # Basically, no cookies or headers are included in the cache key. So this works well for my simple static site. I will have to update it if it gets more complex in the future.
  default_cache_behavior {
	# note: cache_policy_id, even if for custom, is how cache policies are set now (don't use forwarded_values terraform property)
	cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # this is "CachingDisabled" managed cache policy
	allowed_methods = ["GET", "HEAD", "OPTIONS"]
	target_origin_id = local.www_origin_id
	cached_methods = ["GET", "HEAD"]
	viewer_protocol_policy = "redirect-to-https"
  }
  
  # Edge locations: USA, Mexico, Canada, Europe, Israel, Turkey
  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # Use the default, or swap in an ACM cert for your custom domain
    cloudfront_default_certificate = true
  }
}

resource "aws_api_gateway_account" "www" {
	cloudwatch_role_arn = aws_iam_role.apigateway_cloudwatch.arn
}

data "aws_iam_policy_document" "apigateway_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "cloudwatch" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cloudwatch" {
  name   = "default"
  role   = aws_iam_role.apigateway_cloudwatch.id
  policy = data.aws_iam_policy_document.cloudwatch.json
}

resource "aws_iam_role" "apigateway_cloudwatch" {
  name               = "api_gateway_cloudwatch_global"
  assume_role_policy = data.aws_iam_policy_document.apigateway_assume_role.json
}

resource "aws_cloudwatch_log_group" "www_apigateway" {
  name              = "/aws/http-api/www_apigateway/access-logs"
  retention_in_days = 14
}

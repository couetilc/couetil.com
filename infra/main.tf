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

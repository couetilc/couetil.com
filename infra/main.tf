terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = "~> 5.0"
		}
		cloudflare = {
			source = "cloudflare/cloudflare"
			version = "~> 5.0"
		}
		external = {
			source = "hashicorp/external"
			version = "~> 2.0"
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

provider "cloudflare" {
	api_token = data.external.cloudflare_secrets.result.api_token
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

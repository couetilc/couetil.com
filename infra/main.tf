# 4 - switch ssh to a different port (btw is it possible to store SSH config in 1password? Or I guess I would use AWS secret manager and keep it project specific, activate/accessed by my rootkey in 1pass?)
# 5. DNS records?
# 6. I need to restrict outgoing internet traffic from the EC2 instance to only it's runtime dependencies. Builds of a container image to be loaded for a deploys will have already accessed everything it needs from the internet.
# 8. Set up logging and make sure sometime type of monitoring is enabled on the ec2 instance.

# OK VM Image Stuff:
# - cloud init, the user_data is not working for whatever reason.
#    - 
# - need to locked down SSH. No password access, only key access. (so modify system sshd_config)
# - need to set up a Docker credential store on boot: `sudo dnf install -y amazon-ecr-credential-helper` see https://github.com/awslabs/amazon-ecr-credential-helper
# - need to have docker installed, and other dependencies.
# - need to have it pull the image from my ECR repo? Or already have the image on file system somehow?

# cloud init:
# what needs to happen?
# - change user to something else (not "ec2-user")
# - configure iptables (same as aws security group. Also to keep a log of all network requests.)
# - configure the go app as a systemd service (so I can use socket activation for rolling deploys. need to udnerstand socket activation better)
# - what other logging can I configure? application i guess? Other kernel logs? log rotation.
# - install application dependencies? I guess not if docker? or I just deploy the binary? Nothing else on the server. or I just run the container to get isolation, no overhead on linux. And every cloud provider optimizes for containers.
# - what about security updates? for system programs? and the OS itself? How to keep updated? This might be where AWS Systems Manager comes in. There are AMI images where it is included. Like 
# - multipart mime type of cloud-config is awesome. great idea.
# - I can use hashicorp packer tool to make this image have everything at boot. Same syntax as terraform I believe. And will include the latest www go binary. So I rebuild VM on every release.

# Rolling Deploys:
# - the best option for rolling deploys seems to be socket activation with
# systemd. I deploy the new binary, overwriting the old binary, while the old
# process is in memory, then `systemctl restart [service_name]` and the new
# process will be loading, traffic switch to it, and the old process will be
# killed. Not sure about whether in-flight requests will be gracefully handled.
# The only problem with this is I have to add a go dependency to accept the
# systemd socket, rather than the default net.Listen socket. But HAProxy comes
# included with systemd socket activation, so I may just use it for the rolling
# deploys, then when I need to update haproxy itself, then socket activation
# comes in handy. HAProxy also has a graceful restart option as part of
# startup, where it will inherit connections from the old process, so no need
# for systemd.
# - The other option, which may be simpler/typical is using iptables for a
# in-kernel NAT setup. There are "prerouting" and "redirect" directives that
# let you swap requests to another port. Then can send a cancel signal to old
# process, and let it gracefully shutdown.
# - I don't need HAProxy because I don't want to do SSL termination on the
# instance, I'll let AWS take care of that with their default public DNS for
# EC2. And I don't have multiple services running under the same domain name.
# - I can test my rolling deploys by running go-wrk (benchmark tool), starting
# the deploy, and seeing the number of errors.
# - once this works, what about rollback?
# - OK, so I think: HAProxy (with systemd socket activation for rolling
# deploys) -> go router (with haproxy config updates for rolling deploys)
# BUTTTTTTTTTT I think trying out iptables NAT no haproxy is best to try first.
#
# OK so I will want to:
# - create my own iptables chain
# - add rule that forwards from port 80 to the server port
# ```
# iptables -t nat -N WWW
# iptables -t nat -I PREROUTING -p tcp --dport 80 -j WWW
# iptables -t nat -A WWW -p tcp -j REDIRECT --to-ports 9001
# ```
# - And then toggle by
# ```
# iptables -t nat -R WWW 1 -p tcp -j REDIRECT --to-ports 9002
# conntrack -F # flushes connection table so TCP clients are forced to make a new connection, which will now be routed to the new process.
# sudo conntrack -D -p tcp --dport 80 # I think I can use this to only flush the incoming HTTP connections, haven't tested it.
# ```

# TODO: encrypt my tf bucket.

# NOTE: most kernels need to sysctl (Need to put content "net.ipv4.ip_forward = 1" to a file in /etc/sysctl.conf)

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

data "aws_vpc" "default" {
  default = true
}

resource "aws_default_subnet" "a" {
  availability_zone = "us-east-1a"
}

locals {
  vpc = data.aws_vpc.default
  subnet = aws_default_subnet.a
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "www" {
  name        = "www"
  description = "Allow HTTP only from CloudFront"
  vpc_id      = local.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.www.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_cloudfront" {
  security_group_id = aws_security_group.www.id
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_wireguard" {
  security_group_id = aws_security_group.www.id
  cidr_ipv4	    = "0.0.0.0/0"
  from_port         = 51820
  ip_protocol       = "udp"
  to_port           = 51820
}

# so wireguard config will look like
# ```wg
# [Interface]
# Address = 10.0.01/24
# ListenPort = 51820
# PrivateKey = {{ .PrivateKey }}
# # note: these commands should be a small script that checks for the presence of these rules
# PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
# PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
# 
# [Peer]
# PublicKey = _
# AllowedIPs = 10.0.0.2/32
# ```

# I need to make users for all these services on the VM.

// eventually want to close this off, there should be no egress unless to within the VPC
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.www.id
  cidr_ipv4         = "0.0.0.0/0"
  # cidr_ipv4         = local.vpc.cidr_block // todo. or turn off.
  ip_protocol       = "-1" # semantically equivalent to all ports
}

data "aws_ssm_parameter" "www_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

resource "aws_key_pair" "root" {
  key_name = "root"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBqkQhojLRy/U06XCUT2yuAiZjMSKKCkmcC/JS6+ea53"
}

resource "aws_instance" "www" {
  ami                         = data.aws_ssm_parameter.www_ami.value
  instance_type               = "t4g.nano"
  subnet_id                   = local.subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.www.id]
  key_name = aws_key_pair.root.key_name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    service docker start
    # replace with your image
    docker run -d -p 80:8080 --name www ${aws_ecr_repository.www.repository_url}:latest
  EOF
  )
}

resource "aws_cloudfront_distribution" "www" {
  enabled             = true
  default_root_object = ""

  origin {
    domain_name = aws_instance.www.public_dns
    origin_id   = "www"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = 80 // TODO: change default HTTP port to 30000+
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "www"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET","HEAD","OPTIONS"]
    cached_methods         = ["GET","HEAD"]
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
    compress               = true
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

variable "client_public_key" {
  type        = string
  sensitive   = true
}

variable "client_private_key" {
  type        = string
  sensitive   = true
}

variable "server_public_key" {
  type        = string
  sensitive   = true
}

variable "server_private_key" {
  type        = string
  sensitive   = true
}

locals {
  wireguard_keys = {
    client_public = var.client_public_key
    client_private = var.client_private_key
    server_public = var.server_public_key
    server_private = var.server_private_key
  }
}

resource "aws_ssm_parameter" "wireguard" {
  for_each = local.wireguard_keys
  name = "/www/wireguard/${each.key}_key"
  type = "SecureString"
  value = each.value
  tier = "Standard"
}

output "cloudfront_domain_name" {
  description = "CloudFront URL for your service"
  value       = aws_cloudfront_distribution.www.domain_name
}

output "ec2_public_ip" {
  description = "www public ip"
  value       = aws_instance.www.public_ip
}

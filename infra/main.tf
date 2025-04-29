# 2. Create EC2 instance in public subnet.
# 3. Attach security group
# 4 - switch ssh to a different port (btw is it possible to store SSH config in 1password? Or I guess I would use AWS secret manager and keep it project specific, activate/accessed by my rootkey in 1pass?)
# 4. - access only to SSH port, and from Cloudfront to the port of the go server. I can always SSH forward the app to access it remotely for dev work without allowing public access.
# 4. Create Cloudfront Distribution
# 5. DNS records?
# 6. I need to restrict outgoing internet traffic from the EC2 instance to only it's runtime dependencies. Builds of a container image to be loaded for a deploys will have already accessed everything it needs from the internet.
# 7. I want some type of CI/CD system and I want to see what AWS offers. 
# 8. Set up logging and make sure sometime type of monitoring is enabled on the ec2 instance.

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

// eventually want to close this off, there should be no egress unless to within the VPC
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.www.id
  # cidr_ipv4         = "0.0.0.0/0"
  cidr_ipv4         = local.vpc.cidr_block
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_ecs_cluster" "www" {
  name = "www"
}

resource "aws_ecs_cluster_capacity_providers" "www" {
  cluster_name = aws_ecs_cluster.www.name
  capacity_providers = [aws_ecs_capacity_provider.www.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.www.name
    weight            = 1
  }
}

// This looks off. "ecs_assume_role" in title and "ec2.amazonaws.com" in identifiers?
data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name               = "ecs-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}


resource "aws_iam_role_policy_attachment" "ecs_service" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}


resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

data "aws_ssm_parameter" "www_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended/image_id"
}

resource "aws_key_pair" "root" {
  key_name = "root"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBqkQhojLRy/U06XCUT2yuAiZjMSKKCkmcC/JS6+ea53"
}

# resource "aws_instance" "www" {
#   ami                         = data.aws_ssm_parameter.www_ami.value
#   instance_type               = "t4g.nano"
#   subnet_id                   = local.subnet.id
#   associate_public_ip_address = true
#   vpc_security_group_ids      = [aws_security_group.www.id]
#   iam_instance_profile        = aws_iam_instance_profile.ecs_instance_profile.name
#   monitoring		      = true
#   key_name		      = aws_key_pair.root.key_name
#
#   user_data = <<-EOF
#     #!/bin/bash
#     echo "ECS_CLUSTER=${aws_ecs_cluster.www.name}" >> /etc/ecs/ecs.config
# EOF
#
#   tags = {
#     Name = "www"
#   }
# }

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_ecs_task_definition" "www" {
  family                   = "www"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge" // this should be host, right? reduce some network overhead from the container's network virtualization?
  cpu                      = "256" // eventually will make this the VM's cpu and memory
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name         = "www"
    image        = "${aws_ecr_repository.www.repository_url}:latest"
    essential    = true
    portMappings = [{ containerPort = 80, hostPort = 80 }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
	awslogs-group = aws_cloudwatch_log_group.ecs_www.name
	awslogs-region = "us-east-1"
	awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "www" {
  name            = "www"
  cluster         = aws_ecs_cluster.www.id
  task_definition = aws_ecs_task_definition.www.arn
  desired_count   = 1

  depends_on = [
    aws_autoscaling_group.www
  ]

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.www.name
    weight = 1
  }
}

resource "aws_launch_template" "www" {
  name_prefix   = "ecs-"
  image_id      = data.aws_ssm_parameter.www_ami.value
  instance_type = "t4g.nano"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = <<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${aws_ecs_cluster.www.name}" >> /etc/ecs/ecs.config
  EOF

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = local.subnet.id
    security_groups             = [aws_security_group.www.id]
  }

  monitoring {
    enabled = true
  }
}

resource "aws_autoscaling_group" "www" {
  name                      = "www"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = local.subnet.id

  launch_template {
    id      = aws_launch_template.www.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "www"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "www" {
  name = "www"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.www.arn

    managed_scaling {
      status            = "ENABLED"
      target_capacity   = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1000
    }

    # Protect running tasks during ASG scale-in
    managed_termination_protection = "ENABLED"
  }
}

resource "aws_cloudwatch_log_group" "ecs_www" {
  name              = "/ecs/www"
  retention_in_days = 14
}

data "aws_iam_policy_document" "ecs_task_exec_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "ecs_task_execution" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_exec_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_instance" "www" {
  instance_id = one(aws_autoscaling_group.www.instances).instance_id
}

resource "aws_cloudfront_distribution" "www" {
  enabled             = true
  default_root_object = ""

  origin {
    domain_name = data.aws_instance.www
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

output "cloudfront_domain_name" {
  description = "CloudFront URL for your service"
  value       = aws_cloudfront_distribution.www.domain_name
}



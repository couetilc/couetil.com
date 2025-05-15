packer {
	required_plugins {
		amazon = {
			version = "~> 1"
			source = "github.com/hashicorp/amazon"
		}
	}
}

variable "path_www0_conf" { type = string }
variable "path_wg_conf" { type = string }
variable "path_www_bin" { type = string }
variable "path_www_service" { type = string }

# snapshot size is ~1.8GB in size with ebs volume size 8GB, minimal is ~1.3GB
# with volume size around 2GB

data "amazon-parameterstore" "al2023-minimal" {
	name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-arm64"
}

data "amazon-parameterstore" "al2023" {
	name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

source "amazon-ebs" "al2023" {
	instance_type = "t4g.nano"
	ssh_username = "ec2-user"

	source_ami = data.amazon-parameterstore.al2023.value

	ami_name = "packer-al2023-{{timestamp}}"

	tags = {
		service = "www.couetil.com"
	}
}

build {
	sources = [
		"source.amazon-ebs.al2023"
	]

	provisioner "file" {
		sources = [
			var.path_wg_conf,
			var.path_www0_conf,
			var.path_www_bin,
			var.path_www_service,
		]
		destination = "/home/ec2-user/"
	}

	provisioner "shell" {
		env = {
			"wg_conf" = basename(var.path_wg_conf),
			"www0_conf" = basename(var.path_www0_conf),
			"www_bin" = basename(var.path_www_bin),
			"www_service" = basename(var.path_www_service),
		}
		script = "bootstrap.sh"
	}
}

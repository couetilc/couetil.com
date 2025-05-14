packer {
	required_plugins {
		amazon = {
			version = "~> 1"
			source = "github.com/hashicorp/amazon"
		}
	}
}

#data "amazon-ami" "al2023-minimal" {
#	filters = {
#		architecture = "arm64"
#		virtualization-type = "hvm"
#		hypervisor = "xen"
#		ena-support = true // t4g is a Nitro instance
#		product-code = "b6x93o9l9kui3ffv95cpb0nqw"
#	}
#	most_recent = true
#	owners = ["amazon", "aws-marketplace"]
#}

# I want this ami /aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-arm64"
data "amazon-parameterstore" "al2023-minimal" {
	name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-arm64"
}

data "amazon-parameterstore" "al2023" {
	// adds on about .5g to snapshot size compared to minimal, and volume size ends up 8GB instead of 2GB.
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

	provisioner "shell" {
		inline = [
			// update all packages
			"sudo dnf update -y",
			// Install WireGuard tools (kernel module is included in AL2023
			"sudo dnf install -y wireguard-tools",
			// (Optional) Enable a WireGuard interface template
			"sudo systemctl enable wg-quick@wg0",
			// Clean Up
			"sudo dnf clean all",
		]
	}
}

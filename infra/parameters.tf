
variable "client_public_key" {
  description = "WireGuard public key for client"
  type        = string
  sensitive   = true
}

variable "client_private_key" {
  description = "WireGuard private key for client"
  type        = string
  sensitive   = true
}

variable "server_public_key" {
  description = "WireGuard public key for server"
  type        = string
  sensitive   = true
}

variable "server_private_key" {
  description = "WireGuard private key for server"
  type        = string
  sensitive   = true
}

resource "aws_ssm_parameter" "client_public" {
  name = "/wireguard/client1/public_key"
  description = "www.couetil.com wireguard client public key"
  type = "SecureString"
  value_wo = var.client_public_key
  value_wo_version = "0"
  tier = "Standard"
}

resource "aws_ssm_parameter" "client_private" {
  name = "/wireguard/client1/public_key"
  description = "www.couetil.com wireguard client public key"
  type = "SecureString"
  value_wo = var.client_private_key
  value_wo_version = "0"
  tier = "Standard"
}

resource "aws_ssm_parameter" "client_public" {
  name = "/wireguard/client1/public_key"
  description = "www.couetil.com wireguard client public key"
  type = "SecureString"
  value_wo = var.client_public_key
  value_wo_version = "0"
  tier = "Standard"
}

resource "aws_ssm_parameter" "client_public" {
  name = "/wireguard/client1/public_key"
  description = "www.couetil.com wireguard client public key"
  type = "SecureString"
  value_wo = var.client_public_key
  value_wo_version = "0"
  tier = "Standard"
}

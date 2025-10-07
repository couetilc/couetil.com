variable "cloudflare_api_token" {
	description = "Cloudflare API token for managing DNS records"
	type        = string
	sensitive   = true
}

variable "cloudflare_zone_id" {
	description = "Cloudflare Zone ID for couetil.com"
	type        = string
}

# Fetch Cloudflare secrets from 1Password CLI
data "external" "cloudflare_secrets" {
	program = ["sh", "-c", <<-EOT
		echo "{
			\"api_token\": \"$(op read 'op://couetil.com/config/cloudflare/api_token')\",
			\"zone_id\": \"$(op read 'op://couetil.com/config/cloudflare/zone_id')\"
		}"
	EOT
	]
}

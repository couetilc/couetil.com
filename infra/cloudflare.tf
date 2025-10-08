# Reference to existing Cloudflare zone
data "cloudflare_zone" "couetil_com" {
	zone_id = data.external.cloudflare_secrets.result.zone_id
}

# Zone Configuration
# Note: DNSSEC is currently disabled for this zone
# Uncomment to enable DNSSEC management
# resource "cloudflare_zone_dnssec" "couetil_com" {
# 	zone_id = data.external.cloudflare_secrets.result.zone_id
# }

# DNS Records

# ACM validation records - dynamically generated from certificate
resource "cloudflare_dns_record" "acm_validation" {
	for_each = {
		for dvo in aws_acm_certificate.website.domain_validation_options : dvo.domain_name => {
			name   = dvo.resource_record_name
			record = dvo.resource_record_value
			type   = dvo.resource_record_type
		}
	}

	content = each.value.record
	name    = trimsuffix(each.value.name, ".")
	proxied = false
	ttl     = 1
	type    = each.value.type
	zone_id = data.external.cloudflare_secrets.result.zone_id
	settings = {
		flatten_cname = false
	}
}

# Site CNAMEs
resource "cloudflare_dns_record" "connor_couetil_com" {
	content = aws_cloudfront_distribution.website.domain_name
	name    = "connor.couetil.com"
	proxied = false
	ttl     = 1
	type    = "CNAME"
	zone_id = data.external.cloudflare_secrets.result.zone_id
	settings = {
		flatten_cname = false
	}
}

resource "cloudflare_dns_record" "couetil_com" {
	content = aws_cloudfront_distribution.website.domain_name
	name    = "couetil.com"
	proxied = false
	ttl     = 1
	type    = "CNAME"
	zone_id = data.external.cloudflare_secrets.result.zone_id
	settings = {
		flatten_cname = false
	}
}

resource "cloudflare_dns_record" "www_couetil_com" {
	content = aws_cloudfront_distribution.website.domain_name
	name    = "www.couetil.com"
	proxied = false
	ttl     = 1
	type    = "CNAME"
	zone_id = data.external.cloudflare_secrets.result.zone_id
	settings = {
		flatten_cname = false
	}
}

# Email and verification records are managed directly in Cloudflare
# and are not part of this static site infrastructure

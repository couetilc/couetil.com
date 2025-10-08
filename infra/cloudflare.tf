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

# ACM validation records
resource "cloudflare_dns_record" "acm_validation_couetil_com" {
	content = "_3c500bf08bd18e9fdd805f24db0acc20.nfyddsqlcy.acm-validations.aws"
	name    = "_8495bc555139c34a0d56fa85ea40da46.couetil.com"
	proxied = false
	ttl     = 1
	type    = "CNAME"
	zone_id = data.external.cloudflare_secrets.result.zone_id
	settings = {
		flatten_cname = false
	}
}

resource "cloudflare_dns_record" "acm_validation_www_couetil_com" {
	content = "_a2508035ddf1392ffb4d268ada5d11b8.nfyddsqlcy.acm-validations.aws"
	name    = "_c3e4da8dbcf9e64d2c5e18135b0cd188.www.couetil.com"
	proxied = false
	ttl     = 1
	type    = "CNAME"
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
	content = "temporary-couetil-com.pages.dev"
	name    = "couetil.com"
	proxied = true
	ttl     = 1
	type    = "CNAME"
	zone_id = data.external.cloudflare_secrets.result.zone_id
	settings = {
		flatten_cname = false
	}
}

resource "cloudflare_dns_record" "www_couetil_com" {
	content = "temporary-couetil-com.pages.dev"
	name    = "www.couetil.com"
	proxied = true
	ttl     = 1
	type    = "CNAME"
	zone_id = data.external.cloudflare_secrets.result.zone_id
	settings = {
		flatten_cname = false
	}
}

# Fastmail DKIM records
resource "cloudflare_dns_record" "fastmail_dkim_1" {
	comment = "Fastmail"
	content = "fm1.couetil.com.dkim.fmhosted.com"
	name    = "fm1._domainkey.couetil.com"
	proxied = false
	ttl     = 1
	type    = "CNAME"
	zone_id = data.external.cloudflare_secrets.result.zone_id
	settings = {
		flatten_cname = false
	}
}

resource "cloudflare_dns_record" "fastmail_dkim_2" {
	comment = "Fastmail"
	content = "fm2.couetil.com.dkim.fmhosted.com"
	name    = "fm2._domainkey.couetil.com"
	proxied = false
	ttl     = 1
	type    = "CNAME"
	zone_id = data.external.cloudflare_secrets.result.zone_id
	settings = {
		flatten_cname = false
	}
}

resource "cloudflare_dns_record" "fastmail_dkim_3" {
	comment = "Fastmail"
	content = "fm3.couetil.com.dkim.fmhosted.com"
	name    = "fm3._domainkey.couetil.com"
	proxied = false
	ttl     = 1
	type    = "CNAME"
	zone_id = data.external.cloudflare_secrets.result.zone_id
	settings = {
		flatten_cname = false
	}
}

# Fastmail MX records
resource "cloudflare_dns_record" "fastmail_mx_1" {
	comment  = "Fastmail"
	content  = "in1-smtp.messagingengine.com"
	name     = "couetil.com"
	priority = 10
	proxied  = false
	ttl      = 1
	type     = "MX"
	zone_id  = data.external.cloudflare_secrets.result.zone_id
	settings = {}
}

resource "cloudflare_dns_record" "fastmail_mx_2" {
	comment  = "Fastmail"
	content  = "in2-smtp.messagingengine.com"
	name     = "couetil.com"
	priority = 20
	proxied  = false
	ttl      = 1
	type     = "MX"
	zone_id  = data.external.cloudflare_secrets.result.zone_id
	settings = {}
}

# TXT records
resource "cloudflare_dns_record" "google_site_verification" {
	content = "google-site-verification=gL1G1iqvoLA2lLHNiY3blwgtUncHPf8Rq25Crg3jABE"
	name    = "couetil.com"
	proxied = false
	ttl     = 1
	type    = "TXT"
	zone_id = data.external.cloudflare_secrets.result.zone_id
	settings = {}
}

resource "cloudflare_dns_record" "fastmail_spf" {
	comment = "Fastmail"
	content = "v=spf1 include:spf.messagingengine.com ?all"
	name    = "couetil.com"
	proxied = false
	ttl     = 1
	type    = "TXT"
	zone_id = data.external.cloudflare_secrets.result.zone_id
	settings = {}
}

# `www` infrastructure code

This directory contains Terraform configuration for managing the couetil.com infrastructure including AWS resources (S3, CloudFront) and Cloudflare DNS.

## Prerequisites

- Terraform (installed locally as `./terraform`)
- [1Password CLI](https://developer.1password.com/docs/cli/) - for secrets management
- [direnv](https://direnv.net/) - for loading environment variables from `.envrc`
- AWS credentials configured
- Cloudflare API token with DNS edit permissions

## Setup

### Environment Variables

The `.envrc` file at the root of the repository loads credentials from 1Password:

```bash
export CLOUDFLARE_API_TOKEN="$(op read "op://couetil.com/config/cloudflare/api_token")"
export CLOUDFLARE_ZONE_ID="$(op read "op://couetil.com/config/cloudflare/zone_id")"
```

### Terraform Initialization

```bash
cd infra
./terraform init
```

### Running Terraform Commands

All terraform commands require variables to be passed. The easiest way is to source the `.envrc` file:

```bash
source ../.envrc
./terraform plan -var="cloudflare_api_token=$CLOUDFLARE_API_TOKEN" -var="cloudflare_zone_id=$CLOUDFLARE_ZONE_ID"
./terraform apply -var="cloudflare_api_token=$CLOUDFLARE_API_TOKEN" -var="cloudflare_zone_id=$CLOUDFLARE_ZONE_ID"
```

Or use a terraform.tfvars file (not committed to git):

```hcl
cloudflare_api_token = "your-token-here"
cloudflare_zone_id   = "your-zone-id-here"
```

## Cloudflare Management

This infrastructure now manages all Cloudflare DNS records for couetil.com via Terraform.

### DNS Records

The following records are managed in `cloudflare.tf`:

- **ACM Validation Records** - AWS Certificate Manager validation CNAMEs
- **Site CNAMEs** - Main domain and subdomains pointing to Cloudflare Pages
- **Fastmail Records** - DKIM, MX, and SPF records for email
- **Google Site Verification** - TXT record for Google Search Console

### Adding New DNS Records

To add a new DNS record:

1. Add a new `cloudflare_dns_record` resource to `cloudflare.tf`:

```hcl
resource "cloudflare_dns_record" "example" {
  content = "example.com"
  name    = "subdomain.couetil.com"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
  settings = {
    flatten_cname = false
  }
}
```

2. Run `terraform plan` to verify the changes
3. Run `terraform apply` to create the record

### Importing Existing Cloudflare Resources

If you need to import additional Cloudflare resources:

```bash
# Install cf-terraforming (already installed via Homebrew)
brew install cloudflare/cloudflare/cf-terraforming

# Generate configuration for a resource type
cf-terraforming generate --resource-type cloudflare_dns_record

# Generate import commands
cf-terraforming import --resource-type cloudflare_dns_record

# Run the import commands
source ../.envrc
./terraform import -var="cloudflare_api_token=$CLOUDFLARE_API_TOKEN" \
  -var="cloudflare_zone_id=$CLOUDFLARE_ZONE_ID" \
  cloudflare_dns_record.example \
  <zone_id>/<record_id>
```

## AWS Resources

This Terraform configuration also manages:

- **S3 Buckets** - Website hosting and terraform state storage
- **CloudFront Distribution** - CDN for the website
- **CloudFront Functions** - URL rewriting

## AMIs

To get a list of AMIs for use with Amazon through System Manager Parameters:

```sh
aws ssm get-parameters-by-path \
	--path /aws/service/ami-amazon-linux-latest \
	--query 'Parameters[].Name'
```

For raw image information straight from ec2 (this is usually a high number of images):

```sh
aws ec2 describe-images \
	--filters "Name=architecture,Values=arm64" \
	--filters "Name=virtualization-type,Values=hvm" \
	--filters="Name=hypervisor,Values=xen" \
	--filters="Name=ena-support,Values=true" \
	--filters="Name=owner-alias,Values=amazon" \
	--query 'sort_by(Images, &CreationDate)[].Name'
```

## State Management

Terraform state is stored in an S3 bucket (`tf.couetil.com`) with versioning enabled. The state file is managed by the backend configuration in `main.tf`.

# `www` infrastructure code

This directory contains Terraform configuration for managing the couetil.com infrastructure including AWS resources (S3, CloudFront) and Cloudflare DNS.

## Prerequisites

- Terraform CLI (`terraform` available on your PATH)
- [1Password CLI](https://developer.1password.com/docs/cli/) - for secrets management
- AWS credentials configured
- Cloudflare API token with DNS edit permissions
- Optional: [direnv](https://direnv.net/) if you prefer to manage environment variables

## Setup

### Secrets Management

Cloudflare credentials are automatically fetched from 1Password at runtime using the `external` data source in `secrets.tf`. This eliminates the need for environment variables or tfvars files.

### Terraform Initialization

```bash
cd infra
terraform init
```

### Running Terraform Commands

Terraform automatically fetches Cloudflare secrets from 1Password using the `external` data source. Just run:

```bash
terraform plan
terraform apply
```

The secrets are fetched at runtime via the `op` CLI tool.

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
terraform import cloudflare_dns_record.example <zone_id>/<record_id>
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

## Logging and Monitoring

This infrastructure includes comprehensive logging and monitoring:

### Logs

All logs are stored in the `logs.couetil.com` S3 bucket with automatic lifecycle management:
- **Retention**: 90 days total (30 days Standard, 30 days Infrequent Access, 30 days Glacier)
- **CloudFront Access Logs**: `s3://logs.couetil.com/cloudfront/`
- **S3 Access Logs**: `s3://logs.couetil.com/s3-access/`

### CloudWatch Alarms

The following alarms are configured:

**Performance & Errors:**
- CloudFront 4xx error rate >5% (2 consecutive 5-minute periods)
- CloudFront 5xx error rate >1% (2 consecutive 5-minute periods)
- CloudFront origin latency >1 second

**Billing:**
- Monthly spend thresholds: $10, $25, $50

### Setting Up Alert Notifications

After running `terraform apply`, subscribe to SNS topics to receive alerts:

```bash
# Get the SNS topic ARNs from Terraform outputs
terraform output sns_alerts_topic_arn
terraform output sns_billing_alerts_topic_arn

# Subscribe to performance/error alerts
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_alerts_topic_arn) \
  --protocol email \
  --notification-endpoint your@email.com

# Subscribe to billing alerts
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_billing_alerts_topic_arn) \
  --protocol email \
  --notification-endpoint your@email.com

# Confirm the subscription by clicking the link in the email AWS sends
```

You can also use the convenience script:

```bash
./subscribe-to-alerts.sh your@email.com
```

**Important**: Billing alarms require enabling billing alerts in AWS Console:
1. Go to AWS Billing → Billing Preferences
2. Enable "Receive Billing Alerts"

### Viewing Logs

```bash
# List recent CloudFront logs
aws s3 ls s3://logs.couetil.com/cloudfront/ --recursive | tail -20

# Download and view a specific log file
aws s3 cp s3://logs.couetil.com/cloudfront/EXAMPLE.gz - | gunzip | less

# List S3 access logs
aws s3 ls s3://logs.couetil.com/s3-access/
```

## State Management

Terraform state is stored in an S3 bucket (`tf.couetil.com`) with versioning enabled. The state file is managed by the backend configuration in `main.tf`.

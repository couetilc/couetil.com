# couetil.com

Source for https://couetil.com: an Astro-based static site deployed behind CloudFront with Terraform-managed AWS and Cloudflare resources.

## What's Inside
- `astro/` – [Astro site, Docker workflow, and deployment scripts](astro/README.md).
- `infra/` – [Terraform configuration for AWS + Cloudflare](infra/README.md).
- `download_satellite_image.sh` – Standalone Sentinel-2 helper script (creates background image for the site).

## Architecture Snapshot
- **Build** – Astro compiles the site to static assets; a `resume:latest` image is pulled during production builds and copied into `/resume/`.
- **Delivery** – Assets live in the private S3 bucket `www.couetil.com`, fronted by CloudFront with an Origin Access Control and a CloudFront Function for clean URLs.
- **DNS & TLS** – Cloudflare manages DNS; ACM certificates in `us-east-1` cover `couetil.com`, `www`, and `connor` hostnames.
- **State & Secrets** – Terraform state is stored in `s3://tf.couetil.com`; Cloudflare credentials are fetched from 1Password via the Terraform `external` data source.
- **Observability** – CloudFront and S3 logs drain to `logs.couetil.com` with lifecycle policies; CloudWatch alarms send notifications through SNS topics for errors, latency, and billing.

## Common Workflows
- **Develop the site** – Follow the Docker-based workflow in `astro/README.md` for `dev`, `build`, and `run` commands.
- **Manage infrastructure** – Apply Terraform from `infra/` as described in `infra/README.md`, including secret handling and DNS management.
- **Deploy to production** – Use the `deploy` helper in `astro/` after Terraform is in place; the script builds, syncs to S3 with cache-control rules, and invalidates CloudFront.

## Operational Notes
- CloudFront serves `couetil.com`, `www.couetil.com`, and `connor.couetil.com`; DNSSEC is currently disabled but captured in Terraform if re-enabled later.
- Static assets cache for one year while HTML/XML/TXT responses cache for five minutes—behaviour is encoded in the deployment script.
- Subscribe to the SNS topics (see `infra/README.md`) to receive CloudWatch and billing alerts after provisioning.

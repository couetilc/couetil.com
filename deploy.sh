#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage message
usage() {
  echo -e "${BLUE}Usage:${NC} $0 [OPTIONS]"
  echo ""
  echo "Deploy Astro static site to S3 and invalidate CloudFront cache."
  echo ""
  echo -e "${BLUE}Options:${NC}"
  echo "  --skip-build          Skip npm build step (use existing dist/ folder)"
  echo "  --skip-install        Skip npm ci step (assumes dependencies installed)"
  echo "  --skip-invalidation   Skip CloudFront cache invalidation"
  echo "  --dry-run             Show what would be deployed without actually deploying"
  echo "  -h, --help            Show this help message"
  echo ""
  echo -e "${BLUE}Examples:${NC}"
  echo "  $0                           # Full build and deploy"
  echo "  $0 --skip-build              # Deploy existing build"
  echo "  $0 --dry-run                 # Preview what would be deployed"
  echo "  $0 --skip-install --skip-invalidation"
  echo ""
  echo -e "${BLUE}Requirements:${NC}"
  echo "  - AWS CLI configured with appropriate credentials"
  echo "  - Terraform infrastructure already deployed (infra/)"
  echo "  - Docker installed (for building)"
  exit 0
}

# Parse arguments
SKIP_BUILD=false
SKIP_INSTALL=false
SKIP_INVALIDATION=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --skip-install)
      SKIP_INSTALL=true
      shift
      ;;
    --skip-invalidation)
      SKIP_INVALIDATION=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo -e "${RED}Error: Unknown option $1${NC}"
      echo "Run '$0 --help' for usage information."
      exit 1
      ;;
  esac
done

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v aws &> /dev/null; then
  echo -e "${RED}Error: AWS CLI is not installed${NC}"
  exit 1
fi

if ! command -v terraform &> /dev/null; then
  echo -e "${RED}Error: Terraform is not installed${NC}"
  exit 1
fi

if [ "$SKIP_BUILD" = false ] && ! command -v docker &> /dev/null; then
  echo -e "${RED}Error: Docker is not installed${NC}"
  exit 1
fi

if [ ! -d "astro" ]; then
  echo -e "${RED}Error: astro/ directory not found${NC}"
  echo "Run this script from the project root"
  exit 1
fi

if [ ! -d "infra" ]; then
  echo -e "${RED}Error: infra/ directory not found${NC}"
  echo "Run this script from the project root"
  exit 1
fi

echo -e "${GREEN}Starting deployment process...${NC}"

# Build Astro project using Docker
if [ "$SKIP_BUILD" = false ]; then
  echo -e "${YELLOW}Building Astro project with Docker...${NC}"

  # Build the production stage
  docker build \
    --target runtime \
    -t astro-production:latest \
    astro/

  # Extract dist/ folder from the production image
  echo -e "${YELLOW}Extracting dist/ folder from Docker image...${NC}"

  # Remove old dist if exists
  rm -rf astro/dist

  # Create a temporary container and copy the dist folder
  CONTAINER_ID=$(docker create astro-production:latest)
  docker cp ${CONTAINER_ID}:/app/dist astro/dist
  docker rm ${CONTAINER_ID}

  echo -e "${GREEN}Build complete${NC}"
else
  echo -e "${YELLOW}Skipping build step${NC}"

  if [ ! -d "astro/dist" ]; then
    echo -e "${RED}Error: astro/dist directory not found${NC}"
    echo "Cannot skip build without existing dist/ folder"
    exit 1
  fi
fi

# Get infrastructure outputs
echo -e "${YELLOW}Fetching infrastructure details...${NC}"
cd infra
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
cd ..

echo -e "${GREEN}Bucket: ${BUCKET_NAME}${NC}"
echo -e "${GREEN}Distribution: ${DISTRIBUTION_ID}${NC}"

# Sync to S3
echo -e "${YELLOW}Syncing files to S3...${NC}"

DRY_RUN_FLAG=""
if [ "$DRY_RUN" = true ]; then
  DRY_RUN_FLAG="--dryrun"
  echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
fi

aws s3 sync astro/dist/ s3://${BUCKET_NAME}/ \
  ${DRY_RUN_FLAG} \
  --delete \
  --cache-control "public,max-age=3600" \
  --exclude "*.html" \
  --exclude "*.xml"

# Upload HTML files with shorter cache (they change more often)
aws s3 sync astro/dist/ s3://${BUCKET_NAME}/ \
  ${DRY_RUN_FLAG} \
  --delete \
  --cache-control "public,max-age=300" \
  --exclude "*" \
  --include "*.html" \
  --include "*.xml"

# Invalidate CloudFront cache
if [ "$SKIP_INVALIDATION" = false ] && [ "$DRY_RUN" = false ]; then
  echo -e "${YELLOW}Invalidating CloudFront cache...${NC}"
  INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id ${DISTRIBUTION_ID} \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

  echo -e "${GREEN}Cache invalidation created: ${INVALIDATION_ID}${NC}"
else
  echo -e "${YELLOW}Skipping CloudFront cache invalidation${NC}"
fi
echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${YELLOW}Note: CloudFront invalidation may take a few minutes to complete.${NC}"

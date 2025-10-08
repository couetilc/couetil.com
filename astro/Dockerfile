# Development stage
FROM node:22.14.0-alpine AS development

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev)
RUN npm install

# Expose port
EXPOSE 4321

# Start dev server
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]

# Resume stage - rebuild with correct public URL
FROM resume:latest AS resume
RUN ./cli.js build --public-url /resume/

# Build stage
FROM node:22.14.0-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source files
COPY . .

# Build the Astro site
RUN npm run build

# Production stage
FROM node:22.14.0-alpine AS runtime

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --omit=dev

# Copy built site from builder
COPY --from=builder /app/dist ./dist

# Copy resume dist to a subdirectory
COPY --from=resume /app/dist ./dist/resume

# Expose port
EXPOSE 4321

# Start the preview server
CMD ["npm", "run", "preview", "--", "--host", "0.0.0.0"]

# Deploy stage - for deploying to S3 and CloudFront
FROM alpine:3.19 AS deploy

# Install deployment dependencies (minimal - just AWS CLI)
RUN apk add --no-cache \
    aws-cli \
    bash

WORKDIR /workspace

# Copy built dist from builder stage
COPY --from=builder /app/dist ./dist

# Copy deployment script
COPY docker/deploy.sh /workspace/deploy.sh
RUN chmod +x /workspace/deploy.sh

# All configuration passed as environment variables:
# - AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN
# - S3_BUCKET_NAME
# - CLOUDFRONT_DISTRIBUTION_ID

# Default to running the deployment script
ENTRYPOINT ["/workspace/deploy.sh"]
CMD []

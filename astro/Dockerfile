# Development stage
FROM node:22.14.0-alpine AS development

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev)
RUN --mount=type=cache,target=/root/.npm npm install

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
RUN --mount=type=cache,target=/root/.npm npm ci

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
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev

# Copy built site from builder
COPY --from=builder /app/dist ./dist

# Copy resume dist to a subdirectory
COPY --from=resume /app/dist ./dist/resume

# Expose port
EXPOSE 4321

# Start the preview server
CMD ["npm", "run", "preview", "--", "--host", "0.0.0.0"]

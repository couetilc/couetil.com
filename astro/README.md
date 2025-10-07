# couetil.com

Personal website built with [Astro](https://astro.build).

## Development

This project uses Docker for both development and production. The resume is embedded from a separate Docker image (`resume:latest`) during production builds.

### Prerequisites

- [Docker](https://www.docker.com/)
- [direnv](https://direnv.net/) (optional, but recommended)

### Setup

If using direnv:
```sh
direnv allow
```

This adds `bin/` to your PATH, enabling the convenience scripts below.

### Commands

| Command | Action |
| :------ | :----- |
| `dev` | Start development server with hot reload at `localhost:4321` |
| `build` | Build production Docker image |
| `run` | Run production server at `localhost:4321` |
| `stop` | Stop all running containers |
| `deploy` | Deploy to production (S3 + CloudFront) |

Without direnv, prefix commands with `bin/` (e.g., `bin/dev`).

### Development Workflow

**For rapid iteration:**
```sh
dev
```
This runs the Astro dev server in a container with your source files mounted. Changes appear immediately without rebuilding.

**To test production builds:**
```sh
build
run
```
This builds the full production image including the resume integration, then runs it.

## Project Structure

```text
/
├── bin/              # Development scripts
├── public/           # Static assets (CSS, images)
├── src/
│   ├── components/   # Astro components
│   ├── layouts/      # Page layouts
│   └── pages/        # Routes (*.astro files)
├── Dockerfile        # Multi-stage build (dev + prod)
├── docker-compose.yml
├── docker-compose.dev.yml
└── .envrc            # direnv configuration
```

## Production Build

The production build:
1. Pulls the `resume:latest` Docker image
2. Rebuilds the resume with `--public-url /resume/`
3. Builds the Astro site
4. Copies the resume dist to `/resume/` in the final image
5. Serves everything with `npm run preview`

The resume is accessible at `/resume/` when running the production build.

## Deployment

Deploy the site to production (S3 + CloudFront):

```sh
deploy
```

### What the deploy script does:

1. **Dependency check** - Verifies docker, aws-cli, and terraform are installed
2. **Get infrastructure info** - Fetches S3 bucket and CloudFront distribution ID from Terraform outputs
3. **Build** - Creates production Docker image and extracts the `dist/` folder
4. **Upload to S3** - Syncs files with appropriate cache headers:
   - Static assets (JS, CSS, images): 1 year cache
   - HTML/XML: 5 minute cache
5. **Invalidate CloudFront** - Creates cache invalidation for immediate updates

### Prerequisites for deployment:

- **Docker** - For building the production site
- **AWS CLI** - Configured with valid credentials (`aws configure`)
- **Terraform** - Infrastructure must be deployed first (in `../infra/`)

### First-time setup:

1. Deploy infrastructure:
   ```sh
   cd ../infra
   terraform apply
   ```

2. Configure AWS credentials:
   ```sh
   aws configure
   ```

3. Deploy the site:
   ```sh
   cd ../astro
   deploy
   ```

The site will be available at `https://connor.couetil.com` after CloudFront invalidation completes (usually 2-5 minutes).

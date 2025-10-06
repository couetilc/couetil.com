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

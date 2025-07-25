FROM node:current-alpine
RUN apk add --no-cache curl
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app
#COPY package.json pnpm-lock.yaml* ./
#RUN pnpm install
COPY . .
CMD ["pnpm", "build"]
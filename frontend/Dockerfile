# Stage 1: Build
FROM node:20-alpine AS build

WORKDIR /app

COPY package.json pnpm-lock.yaml* ./
RUN corepack enable && pnpm install --frozen-lockfile

COPY . .
RUN pnpm run build

# Stage 2: Serve
FROM nginx:alpine

# Base-image security patches. The alpine bases currently ship libcrypto3/libssl3 3.5.7-r0,
# which Trivy flags HIGH (CVE-2026-14456, OpenSSL QUIC-server DoS, fixed in 3.5.8-r0). These
# come from the base layer, so this is required even though nothing below installs them.
RUN apk upgrade --no-cache

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

# Stock nginx needs root to bind :80 and write /var/cache/nginx; a non-root USER requires the
# unprivileged image and a port change across compose and the launcher. Local-dev container,
# not a public-facing service, so this is exempt per global CLAUDE.md section 9. Revisit if
# this is ever exposed beyond localhost.
# nosemgrep: dockerfile.security.missing-user.missing-user
CMD ["nginx", "-g", "daemon off;"]

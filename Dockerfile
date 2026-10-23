# Resolved image digests are recorded in docs/deployment/STATUS.vi.md.
ARG NODE_IMAGE=node:22-alpine@sha256:0a7108bf6c7bf5de370ffb1a3ed6be93d405b43ff159f681a8d18c0e2bc2e402
ARG NGINX_IMAGE=nginx/nginx-unprivileged:stable-alpine@sha256:517607ae849a46afbd400616a783e4ead0290f52d20ccc0618ccea1a49362474
FROM ${NODE_IMAGE} AS build
WORKDIR /app
ENV ASTRO_TELEMETRY_DISABLED=1
COPY app/package.json app/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY app/ ./
ARG APP_REVISION=local-development
ENV APP_REVISION=${APP_REVISION}
RUN npm run build && npm test

FROM ${NGINX_IMAGE} AS runtime
USER 0
RUN apk upgrade --no-cache zlib musl musl-utils \
    && apk --no-network list --installed zlib musl musl-utils

COPY infra/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=build --chown=101:101 /app/dist/ /usr/share/nginx/html/
USER 101:101
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
ENTRYPOINT ["nginx", "-g", "daemon off;"]

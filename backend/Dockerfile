# Backend API - Express + Mongoose
FROM node:20-alpine

# Small init so SIGTERM is forwarded to node (clean pod / container shutdown)
RUN apk add --no-cache tini

WORKDIR /app

# Install dependencies first for better layer caching
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# App source
COPY . .

# Default container port (overridable via env). Host 5000 is fine inside containers.
ENV PORT=5000
EXPOSE 5000

# Drop root
USER node

# Container-level health check (Kubernetes uses its own probes; this helps docker-compose)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT}/health" > /dev/null 2>&1 || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "server.js"]

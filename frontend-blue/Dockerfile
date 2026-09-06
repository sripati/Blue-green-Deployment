# Blue frontend - Basic registration UI (Express static server + /api reverse proxy)
FROM node:20-alpine

RUN apk add --no-cache tini

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY . .

# Both frontends listen on 3000 inside the container so one K8s Service targetPort fits both.
ENV PORT=3000
ENV BACKEND_URL=http://backend:5000
EXPOSE 3000

USER node

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT}/health" > /dev/null 2>&1 || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "server.js"]

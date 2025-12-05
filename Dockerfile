# v0.8.1-rc2

# Base node image
FROM node:20-alpine AS node

# Install jemalloc
RUN apk add --no-cache jemalloc
RUN apk add --no-cache python3 py3-pip uv

# Set environment variable to use jemalloc
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2

# Add `uv` for extended MCP support
COPY --from=ghcr.io/astral-sh/uv:0.6.13 /uv /uvx /bin/
RUN uv --version

RUN mkdir -p /app && chown node:node /app
WORKDIR /app

USER node

COPY --chown=node:node package.json package-lock.json ./
COPY --chown=node:node api/package.json ./api/package.json
COPY --chown=node:node client/package.json ./client/package.json
COPY --chown=node:node packages/data-provider/package.json ./packages/data-provider/package.json
COPY --chown=node:node packages/data-schemas/package.json ./packages/data-schemas/package.json
COPY --chown=node:node packages/api/package.json ./packages/api/package.json

RUN \
    # Allow mounting of these files, which have no default
    touch .env ; \
    # Create directories for the volumes to inherit the correct permissions
    mkdir -p /app/client/public/images /app/api/logs /app/uploads ; \
    npm config set fetch-retry-maxtimeout 600000 ; \
    npm config set fetch-retries 5 ; \
    npm config set fetch-retry-mintimeout 15000 ; \
    npm ci --no-audit

COPY --chown=node:node . .

RUN \
    # React client build
    NODE_OPTIONS="--max-old-space-size=2048" npm run frontend; \
    npm prune --production; \
    npm cache clean --force

# Create librechat.yaml configuration file at build time
RUN echo 'version: 1.2.1' > /app/librechat.yaml && \
    echo 'cache: true' >> /app/librechat.yaml && \
    echo 'endpoints:' >> /app/librechat.yaml && \
    echo '  custom:' >> /app/librechat.yaml && \
    echo '    - name: "Sportsbook RAG"' >> /app/librechat.yaml && \
    echo '      apiKey: "sk-optional"' >> /app/librechat.yaml && \
    echo '      baseURL: "https://sportsbook-rag.up.railway.app/v1"' >> /app/librechat.yaml && \
    echo '      models:' >> /app/librechat.yaml && \
    echo '        default:' >> /app/librechat.yaml && \
    echo '          - "sportsbook-rag"' >> /app/librechat.yaml && \
    echo '        fetch: false' >> /app/librechat.yaml && \
    echo '      titleConvo: true' >> /app/librechat.yaml && \
    echo '      titleModel: "sportsbook-rag"' >> /app/librechat.yaml && \
    echo '      modelDisplayLabel: "Sportsbook RAG"' >> /app/librechat.yaml && \
    echo '      summarize: false' >> /app/librechat.yaml && \
    echo '      summaryModel: "sportsbook-rag"' >> /app/librechat.yaml && \
    echo '      forcePrompt: false' >> /app/librechat.yaml && \
    chown node:node /app/librechat.yaml && \
    cat /app/librechat.yaml

# Node API setup
EXPOSE 3080
ENV HOST=0.0.0.0
CMD ["npm", "run", "backend"]

# Optional: for client with nginx routing
# FROM nginx:stable-alpine AS nginx-client
# WORKDIR /usr/share/nginx/html
# COPY --from=node /app/client/dist /usr/share/nginx/html
# COPY client/nginx.conf /etc/nginx/conf.d/default.conf
# ENTRYPOINT ["nginx", "-g", "daemon off;"]

# ==========================================
# STAGE 1: DEPENDENCY BUILDER
# ==========================================
FROM node:20-alpine AS builder
WORKDIR /app/backend

# Copy package manifests first for optimal Docker layer caching
COPY backend/package*.json ./

# Install only production dependencies
RUN npm ci --only=production && npm cache clean --force

# ==========================================
# STAGE 2: HARDENED PRODUCTION RUNTIME
# ==========================================
FROM node:20-alpine

# Security: Upgrade OS packages to patch known CVEs for Trivy scan
RUN apk update && apk upgrade --no-cache

WORKDIR /app

# Copy production node_modules from builder stage
COPY --from=builder /app/backend/node_modules ./backend/node_modules

# Copy application source & static frontend assets
COPY backend/ ./backend/
COPY frontend/ ./frontend/
COPY images/ ./images/

# Security: Remove unused npm CLI while still root, then switch to non-root 'node' user
RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx && \
    chown -R node:node /app
USER node

WORKDIR /app/backend

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

CMD ["node", "server.js"]
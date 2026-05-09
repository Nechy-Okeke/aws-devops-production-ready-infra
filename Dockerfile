# syntax=docker/dockerfile:1

# ---------- Build stage ----------
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies first (better layer caching)
COPY app/package.json ./
RUN npm install --omit=dev

# Copy application code
COPY app ./app

# ---------- Runtime stage ----------
FROM node:20-alpine AS runtime

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Install curl for ECS container healthCheck (curl used by healthCheck command)
RUN apk add --no-cache curl

WORKDIR /app

# Copy node_modules and app from builder stage
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/app ./app

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

USER appuser

CMD ["node", "app/app.js"]

# Frontend Dockerfile for PM Master V2
# Multi-stage build for Flutter web application

# Stage 1: Build the Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# Set working directory
WORKDIR /app

# Copy pubspec files first for better caching
COPY pubspec.yaml pubspec.lock ./

# Get Flutter dependencies
RUN flutter pub get

# Copy only the Flutter source code (exclude backend)
COPY lib ./lib
COPY web ./web
COPY assets ./assets
COPY analysis_options.yaml ./

# Create a dummy .env file for build (real config injected at runtime)
RUN echo "# Placeholder - config injected at runtime" > .env

# Build the web app without environment config (will be injected at runtime)
RUN flutter build web --release --dart-define=PLACEHOLDER_BUILD=true

# Stage 2: Serve the web app with nginx
FROM nginx:alpine

# Install necessary packages
RUN apk add --no-cache curl bash

# Copy the built web app from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Create runtime config injection script
RUN cat > /docker-entrypoint.d/00-inject-env.sh << 'EOF'
#!/bin/bash
set -e

# Create runtime config JavaScript file
cat > /usr/share/nginx/html/assets/config.js << JSEOF
window.ENV_CONFIG = {
  SUPABASE_URL: "${SUPABASE_URL}",
  SUPABASE_ANON_KEY: "${SUPABASE_ANON_KEY}",
  API_BASE_URL: "${API_BASE_URL:-http://localhost:8000}",
  FLUTTER_SENTRY_ENABLED: "${FLUTTER_SENTRY_ENABLED:-false}",
  FLUTTER_SENTRY_DSN: "${FLUTTER_SENTRY_DSN:-}",
  FLUTTER_FIREBASE_ANALYTICS_ENABLED: "${FLUTTER_FIREBASE_ANALYTICS_ENABLED:-false}"
};
JSEOF

# Inject config script into index.html before any other scripts
sed -i 's|<base href="/">|<base href="/"><script src="assets/config.js"></script>|' /usr/share/nginx/html/index.html

echo "Runtime configuration injected successfully"
EOF

RUN chmod +x /docker-entrypoint.d/00-inject-env.sh

# Create nginx config
RUN echo 'server { \
        listen 80; \
        server_name localhost; \
        root /usr/share/nginx/html; \
        index index.html; \
        \
        location / { \
            try_files $uri $uri/ /index.html; \
        } \
        \
        location /api { \
            proxy_pass http://backend:8000; \
            proxy_set_header Host $host; \
            proxy_set_header X-Real-IP $remote_addr; \
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
            proxy_set_header X-Forwarded-Proto $scheme; \
        } \
    }' > /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Start nginx (entrypoint scripts run automatically)
CMD ["nginx", "-g", "daemon off;"]
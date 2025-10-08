# Flutter Web Dockerfile
# Note: Edit lib/config.dart before building
# Set apiBaseUrl to 'http://backend:8000' for Docker

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

# Build the web app with WebAssembly - configuration comes from lib/config.dart
# Note: lib/config.dart must exist before building this image
RUN flutter build web --release --wasm

# Stage 2: Serve the web app with nginx
FROM nginx:alpine

# Install necessary packages for health check
RUN apk add --no-cache curl

# Copy the built web app from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Create nginx config with proper MIME types for Flutter WebAssembly
RUN echo 'server { \
        listen 80; \
        server_name localhost; \
        root /usr/share/nginx/html; \
        index index.html; \
        \
        # Gzip compression (exclude wasm - already compressed) \
        gzip on; \
        gzip_vary on; \
        gzip_min_length 1024; \
        gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/javascript application/xml+rss application/json; \
        \
        # WASM files - disable gzip, set long cache \
        location ~* \\.wasm$ { \
            gzip off; \
            expires 1y; \
            add_header Cache-Control "public, immutable"; \
        } \
        \
        # .mjs files (ES modules) - ensure correct MIME type \
        location ~* \\.mjs$ { \
            default_type text/javascript; \
            expires 1y; \
            add_header Cache-Control "public, immutable"; \
        } \
        \
        # Cache static assets \
        location ~* \\.(?:css|js|woff2?|ttf|otf|eot|svg|png|jpg|jpeg|gif|ico)$ { \
            expires 1y; \
            add_header Cache-Control "public, immutable"; \
        } \
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
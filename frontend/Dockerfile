# ── Stage 1: Build ──────────────────────────────────────────────
# Using a pre-built Flutter image is more reliable on platforms like Render
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Copy project files
COPY . .

# Build Args for mapping to backend
ARG BACKEND_HOST=uslove-backend.onrender.com
ARG USE_HTTPS=true

# Get dependencies and build web
RUN flutter config --no-analytics
RUN flutter pub get
RUN flutter build web \
    --dart-define=SERVER_HOST=${BACKEND_HOST} \
    --dart-define=USE_HTTPS=${USE_HTTPS}

# ── Stage 2: Serve ──────────────────────────────────────────────
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Copy build artifacts
COPY --from=build /app/build/web .

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

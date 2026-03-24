# ── Stage 1: Build ──────────────────────────────────────────────
FROM debian:bullseye-slim AS build
WORKDIR /app

# Install dependencies for Flutter
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Verify flutter installation
RUN flutter --version

# Copy project files
COPY . .

# Build Args for mapping to backend
ARG BACKEND_HOST=uslove-backend.onrender.com
ARG USE_HTTPS=true

# Get dependencies and build web
RUN flutter pub get
RUN flutter build web \
    --dart-define=SERVER_HOST=${BACKEND_HOST} \
    --dart-define=USE_HTTPS=${USE_HTTPS}

# ── Stage 2: Serve ──────────────────────────────────────────────
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Copy build artifacts
COPY --from=build /app/build/web .

# Copy custom nginx config if needed (optional)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

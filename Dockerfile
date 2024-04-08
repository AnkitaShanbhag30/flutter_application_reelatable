# Stage 1: Build the Flutter app
FROM ubuntu:latest AS build-stage

WORKDIR /app

# Install dependencies and Flutter SDK
RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils zip libglu1-mesa && \
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/app/flutter/bin:${PATH}"

# Enable Flutter web support
RUN flutter config --enable-web

# Copy the Flutter app to the container and build it
COPY . .
RUN flutter pub get
RUN flutter build web

# Stage 2: Serve the Flutter app with nginx
FROM nginx:latest

# Copy the built Flutter app from the build stage to the nginx html directory
COPY --from=build-stage /app/build/web /usr/share/nginx/html

# Expose port 80 for the web server
EXPOSE 80

# Start nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
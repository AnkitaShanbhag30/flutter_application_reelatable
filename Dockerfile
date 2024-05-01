# # Use Ubuntu 20.04 for amd64 as the base image for the build stage
# FROM ubuntu:20.04 AS build-stage

# # Install dependencies
# RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa wget

# # Create a non-root user and switch to it
# RUN useradd -ms /bin/bash newuser
# USER newuser
# WORKDIR /home/newuser

# # Download and install Flutter manually
# RUN git clone https://github.com/flutter/flutter.git /home/newuser/flutter
# RUN cd /home/newuser/flutter && git checkout stable

# # Set the Flutter tool in the path
# ENV PATH="/home/newuser/flutter/bin:${PATH}"

# # Trigger download of Dart SDK by running flutter precache
# RUN flutter precache

# # Enable Flutter web features
# RUN flutter config --enable-web

# # Copy the Flutter project files into the container and set ownership to the new user
# COPY --chown=newuser:newuser . .

# # Get Flutter dependencies
# RUN flutter pub get --verbose

# # Build the Flutter web application
# RUN flutter build web --release --web-renderer=html

# Use nginx latest official image as the base for the final stage
FROM nginx:latest

# Copy the built Flutter web app to the nginx html directory
# COPY --from=build-stage /home/newuser/build/web /usr/share/nginx/html
COPY ./build/web /usr/share/nginx/html

# Expose port 80 to the host so that the web server can be accessed externally
EXPOSE 80

# Start nginx in the foreground to keep the container running.
CMD ["nginx", "-g", "daemon off;"]
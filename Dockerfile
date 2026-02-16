# Use a lightweight Java runtime (Alpine Linux) to keep the image small
FROM eclipse-temurin:17-jre-alpine

# Set the working directory inside the container
WORKDIR /app

# Install curl and bash (needed for downloading segments and running the start script)
RUN apk add --no-cache curl bash unzip

# --- Download BRouter ---
# We use a specific version (1.7.8) known to be stable.
# It downloads the zip, unzips it, and removes the zip file to save space.
RUN curl -L -o brouter.zip https://github.com/abrensch/brouter/releases/download/v1.7.8/brouter-1.7.8.zip && \
    unzip brouter.zip && \
    rm brouter.zip

# Create necessary folders for data
RUN mkdir -p segments4 profiles customprofiles

# --- Add Configuration ---
# Copy the start script (you need to create this file too, see below)
COPY start.sh .
RUN chmod +x start.sh

# Copy standard profiles (e.g., trekking, fastbike)
# You must have a 'profiles' folder in your repo with .brf files
COPY profiles/ ./profiles/

# --- Server Setup ---
# Expose BRouter's default port
EXPOSE 17777

# Run the start script when the container launches
CMD ["./start.sh"]

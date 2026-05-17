# Base Image: Ubuntu 24.04
FROM ubuntu:24.04

# Prevent interactive prompts during apt installations
ENV DEBIAN_FRONTEND=noninteractive

# Update apt, install the headless JRE and required tools
RUN apt-get update && \
    apt-get install -y openjdk-21-jre-headless wget git build-essential && \
    rm -rf /var/lib/apt/lists/*

# Hardening Step: Create a dedicated, non-root user (Ubuntu syntax)
RUN groupadd -r mcgroup && useradd -r -g mcgroup mcuser

# Install mcrcon for local in-service administration (Ubuntu syntax)
RUN git clone https://github.com/Tiiffi/mcrcon.git /tmp/mcrcon \
    && cd /tmp/mcrcon && make && make install \
    && rm -rf /tmp/mcrcon \
    && apt-get purge -y git build-essential \
    && apt-get autoremove -y

# Create directories and download the Paper server binary
WORKDIR /data
RUN mkdir -p /opt/minecraft && \
    wget -O /opt/minecraft/paper.jar https://fill-data.papermc.io/v1/objects/4b011f5adb5f6c72007686a223174fce82f31aeb4b34faf4652abc840b47e640/paper-1.20.6-151.jar

# Add entrypoint script
COPY entrypoint.sh /opt/minecraft/entrypoint.sh

# Strip Windows line endings (CRLF to LF) and make the script executable
RUN sed -i 's/\r$//' /opt/minecraft/entrypoint.sh && chmod +x /opt/minecraft/entrypoint.sh

# Apply permissions for the non-root user
RUN chown -R mcuser:mcgroup /data /opt/minecraft && \
    chmod +x /opt/minecraft/entrypoint.sh

# Drop root privileges
USER mcuser

# Expose Minecraft TCP and RCON TCP
EXPOSE 25565 25575

ENTRYPOINT ["/opt/minecraft/entrypoint.sh"]
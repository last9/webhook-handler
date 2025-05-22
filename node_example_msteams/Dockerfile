FROM node:18-slim

# Create app directory and set ownership
WORKDIR /app

# Create a non-root user
RUN groupadd -r webhook && useradd -r -g webhook webhook

# Install app dependencies
COPY package*.json ./
RUN npm install --production

# Bundle app source
COPY . .

# Create necessary directories
RUN mkdir -p /app/logs /app/certs && \
    chown -R webhook:webhook /app && \
    chmod -R 777 /app/logs

# Switch to non-root user
USER webhook

# Expose HTTPS port
EXPOSE 443

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f https://localhost:443/health || exit 1

# Add labels
LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="MS Teams Webhook Handler"
LABEL version="1.0.0"

# Create volumes for logs and certificates
VOLUME ["/app/logs", "/app/certs"]

# Start the application
CMD ["node", "server.js"] 
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

# Create log directory
RUN mkdir -p /app/logs && \
    chown -R webhook:webhook /app/logs

# Set proper permissions
RUN chown -R webhook:webhook /app

# Switch to non-root user
USER webhook

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Add labels
LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="MS Teams Webhook Handler"
LABEL version="1.0.0"

# Create volume for logs
VOLUME ["/app/logs"]

# Start the application
CMD ["node", "server.js"] 
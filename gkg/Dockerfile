FROM node:18-alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Create app directory
WORKDIR /app

# Create configuration inline
RUN echo '{ \
  "server": { \
    "host": "0.0.0.0", \
    "port": 27495, \
    "mode": "mcp" \
  }, \
  "mcp": { \
    "name": "gkg-server", \
    "version": "1.0.0", \
    "description": "GitLab Knowledge Graph MCP Server" \
  }, \
  "gitlab": { \
    "url": "https://gitlab.com", \
    "token": "${GITLAB_TOKEN:-}" \
  }, \
  "knowledge_graph": { \
    "storage_path": "/data/gkg", \
    "index_repositories": true, \
    "auto_sync": true \
  }, \
  "logging": { \
    "level": "info", \
    "file": "/data/gkg/logs/gkg.log" \
  } \
}' > /app/config.json

# Create a simple MCP-compatible HTTP server
COPY mcp-server.js /app/mcp-server.js

# Create data directory
RUN mkdir -p /data/gkg/logs

# Expose port
EXPOSE 27495

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:27495/status || exit 1

# Run the MCP server
CMD ["node", "mcp-server.js"]
FROM ubuntu:22.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download and install GKG directly
RUN curl -fsSL https://gitlab.com/gitlab-org/rust/knowledge-graph/-/raw/main/install.sh | bash

# Create working directory
WORKDIR /app

# Create volume for code repositories
VOLUME ["/repositories"]

# Expose GKG server port
EXPOSE 27495

# Add gkg to PATH
ENV PATH="/root/.local/bin:$PATH"

# Default command
CMD ["gkg", "server", "start", "--host", "0.0.0.0", "--port", "27495"]
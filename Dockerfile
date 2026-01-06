FROM alpine:latest

RUN apk add --no-cache bash curl jq

# Receive non-sensitive env vars from the runner
ARG REPORT_PATH
ENV REPORT_PATH=${REPORT_PATH:-""}

ARG ENDPOINT_URL
ENV ENDPOINT_URL=${ENDPOINT_URL:-""}

ENV REPO_PATH="/github/workspace"

# Note: API_KEY should be passed at runtime via -e flag, not baked into the image
# This prevents it from being stored in image layers and metadata

# Set the working directory
WORKDIR $REPO_PATH

# Copy entrypoint script
COPY entrypoint.sh /usr/bin/entrypoint.sh
# Make the entrypoint script executable
RUN chmod +x /usr/bin/entrypoint.sh

# run entrypoint
ENTRYPOINT [ "/usr/bin/entrypoint.sh" ]

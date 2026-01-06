#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  echo "Loading configuration from .env file..."
  # Export variables from .env, ignoring comments and empty lines
  export $(grep -v '^#' .env | grep -v '^$' | xargs)
else
  echo "ERROR: .env file not found!"
  echo "Please copy .env.example to .env and configure your settings."
  exit 1
fi

# Validate required variables
if [ -z "$REPORT_PATH" ]; then
  echo "ERROR: REPORT_PATH is not set in .env file"
  exit 1
fi

if [ -z "$ENDPOINT_URL" ]; then
  echo "ERROR: ENDPOINT_URL is not set in .env file"
  exit 1
fi

if [ -z "$API_KEY" ]; then
  echo "ERROR: API_KEY is not set in .env file"
  exit 1
fi

# Set default image name if not provided
IMAGE_NAME=${IMAGE_NAME:-"imed-cortex-action:latest"}
IMAGE_IS_BUILT=0

# First check if docker image is already built
if docker image inspect $IMAGE_NAME >/dev/null 2>&1; then
  echo "ImedCortexAction Docker image already exists."
  # IMAGE_IS_BUILT=1
fi

if [ $IMAGE_IS_BUILT -eq 0 ]; then
  echo "Building ImedCortexAction Docker image..."
  docker build -t $IMAGE_NAME .
fi

echo "Uploading report from $REPORT_PATH"
docker run -v "$REPORT_PATH:/github/workspace/report.json" \
  -e REPORT_PATH="/github/workspace/report.json" \
  -e API_KEY="$API_KEY" \
  -e ENDPOINT_URL="$ENDPOINT_URL" \
  $IMAGE_NAME

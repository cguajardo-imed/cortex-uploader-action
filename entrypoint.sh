#!/bin/sh -l

# Exit on error
set -e

# Validate required environment variables
if [ -z "$ENDPOINT_URL" ]; then
  echo "ERROR: ENDPOINT_URL environment variable is not set. Exiting."
  exit 1
fi

if [ -z "$REPORT_PATH" ]; then
  echo "ERROR: REPORT_PATH environment variable is not set. Exiting."
  exit 1
fi

if [ ! -f "$REPORT_PATH" ]; then
  echo "ERROR: Report file not found at $REPORT_PATH. Exiting."
  exit 1
fi

if [ -z "$API_KEY" ]; then
  echo "ERROR: API_KEY environment variable is not set. Exiting."
  exit 1
fi

# Make the curl request and capture both response and HTTP status code
echo "Sending report..."
http_code=$(curl --silent --write-out "%{http_code}" --output /tmp/response.txt \
  --request POST \
  --url "$ENDPOINT_URL" \
  --header "content-type: multipart/form-data" \
  --header "X-API-Key: $API_KEY" \
  --form "report=@$REPORT_PATH")

curl_exit_code=$?

# Check if curl command succeeded
if [ $curl_exit_code -ne 0 ]; then
  echo "ERROR: curl command failed with exit code $curl_exit_code"
  if [ -n "$GITHUB_OUTPUT" ]; then
    {
      echo "success=false"
      echo "message=Failed to connect to endpoint"
    } >> "$GITHUB_OUTPUT"
  fi
  exit 1
fi

# Read the response body
response=$(cat /tmp/response.txt)
rm -f /tmp/response.txt

echo "Response: $response"
echo "HTTP Status Code: $http_code"

# Initialize variables
success="false"
message=""

# Check HTTP status code first
if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
  # Try to parse JSON response
  if echo "$response" | jq empty 2>/dev/null; then
    message=$(echo "$response" | jq -r '.message // empty')

    if [ "$http_code" -eq 200 ] 2>/dev/null; then
      success="true"
    else
      success="false"
      message="${message:-Request failed with status $status_code}"
    fi
  else
    # Response is not valid JSON
    message="Response is not valid JSON"
    success="true"  # HTTP succeeded even if JSON parsing failed
  fi
else
  # HTTP error
  message=$(echo "$response" | jq -r '.error // empty')
  if [ -z "$message" ]; then
    message="HTTP request failed with status code $http_code"
  fi
  success="false"
fi

echo "--------------------------------------"
echo "Message: $message"
echo "Success: $success"
echo "--------------------------------------"

# Write output for GitHub Actions
if [ -n "$GITHUB_OUTPUT" ]; then
  {
    echo "success=$success"
    echo "message=$message"
  } >> "$GITHUB_OUTPUT"
fi

# Exit with appropriate code
if [ "$success" = "true" ]; then
  exit 0
else
  exit 1
fi

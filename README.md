# Imed Cortex Report Uploader Action

This GitHub Action automates the process of uploading security scan reports to the Imed Cortex platform. It supports various security scanning tools including Trivy, Gitleaks, and other SARIF-compatible scanners. This action is designed to be used in CI/CD pipelines to ensure that scan reports are consistently uploaded after security scans are executed.

## Features

- 🔒 Secure API key-based authentication
- 📤 Automatic report upload to Imed Cortex
- ✅ Validation of report files and environment variables
- 🔍 Detailed error reporting and logging
- 🐳 Lightweight Docker-based implementation

## Usage

### Basic Example

```yaml
name: Security Scan and Upload

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Run security scan
        # Run your preferred security scanner here
        # Example with Trivy:
        run: |
          docker run --rm -v ${{ github.workspace }}:/workspace aquasec/trivy:latest \
            fs --format json --output /workspace/scan-results.json /workspace

      - name: Upload to Imed Cortex
        uses: your-org/cortex-action@v1
        with:
          endpoint_url: 'https://cortex.example.com/api/upload/sarif'
          api_key: ${{ secrets.CORTEX_API_KEY }}
          report_path: './scan-results.json'
```

### Advanced Example with Multiple Scans

```yaml
jobs:
  trivy-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Trivy scan
        run: |
          docker run --rm -v ${{ github.workspace }}:/workspace aquasec/trivy:latest \
            fs --format json --output /workspace/trivy-results.json /workspace
      
      - name: Upload Trivy results
        uses: your-org/cortex-action@v1
        with:
          endpoint_url: ${{ vars.CORTEX_ENDPOINT_URL }}
          api_key: ${{ secrets.CORTEX_API_KEY }}
          report_path: './trivy-results.json'

  gitleaks-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Run Gitleaks scan
        run: |
          docker run --rm -v ${{ github.workspace }}:/workspace \
            zricethezav/gitleaks:latest detect \
            --source /workspace --report-path /workspace/gitleaks-results.json
      
      - name: Upload Gitleaks results
        uses: your-org/cortex-action@v1
        with:
          endpoint_url: ${{ vars.CORTEX_ENDPOINT_URL }}
          api_key: ${{ secrets.CORTEX_API_KEY }}
          report_path: './gitleaks-results.json'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `endpoint_url` | Full endpoint URL for Imed Cortex platform | Yes | - |
| `api_key` | API key for authentication with Imed Cortex | Yes | - |
| `report_path` | Path to the security scan report file (JSON format) | Yes | - |

## Outputs

| Output | Description |
|--------|-------------|
| `success` | Boolean indicating if the report upload was successful |
| `message` | Detailed message about the upload result |
| `status_code` | HTTP status code from the upload request |

## Example with Output Handling

```yaml
- name: Upload to Imed Cortex
  id: cortex-upload
  uses: your-org/cortex-action@v1
  with:
    endpoint_url: ${{ vars.CORTEX_ENDPOINT_URL }}
    api_key: ${{ secrets.CORTEX_API_KEY }}
    report_path: './scan-results.json'

- name: Check upload result
  if: steps.cortex-upload.outputs.success == 'false'
  run: |
    echo "Upload failed: ${{ steps.cortex-upload.outputs.message }}"
    echo "Status code: ${{ steps.cortex-upload.outputs.status_code }}"
    exit 1
```

## Local Testing

### Prerequisites

- Docker installed and running
- A valid report file to upload
- Access to Imed Cortex endpoint and API key

### Configuration

The test scripts use a `.env` file for configuration. This keeps sensitive data like API keys out of the scripts themselves.

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with your values:**
   ```bash
   # Example .env file content
   REPORT_PATH=/path/to/your/scan-results.json
   ENDPOINT_URL=https://cortex.example.com/api/upload/sarif
   API_KEY=your-actual-api-key-here
   IMAGE_NAME=imed-cortex-action:latest
   ```

   For Windows, use Windows paths:
   ```bash
   REPORT_PATH=C:\path\to\your\scan-results.json
   ```

   For WSL, use WSL paths:
   ```bash
   REPORT_PATH=/mnt/c/path/to/your/scan-results.json
   ```

3. **Run the test script:**

   **Bash (Linux/macOS/WSL):**
   ```bash
   ./test.sh
   ```

   **PowerShell (Windows):**
   ```powershell
   ./test.ps1
   ```

The scripts will:
- ✅ Load configuration from `.env`
- ✅ Validate all required variables are set
- ✅ Build the Docker image if needed
- ✅ Upload the report to Imed Cortex

### Manual Testing (Without .env)

If you prefer to test manually without the `.env` file:

**Bash:**
```bash
# Build the Docker image
docker build -t imed-cortex-action:latest .

# Run the action
docker run -v "/path/to/report.json:/github/workspace/report.json" \
  -e REPORT_PATH="/github/workspace/report.json" \
  -e API_KEY="your-api-key-here" \
  -e ENDPOINT_URL="https://cortex.example.com/api/upload/sarif" \
  imed-cortex-action:latest
```

**PowerShell:**
```powershell
# Build the Docker image
docker build -t imed-cortex-action:latest .

# Run the action
docker run -v "C:\path\to\report.json:/github/workspace/report.json" `
  -e REPORT_PATH="/github/workspace/report.json" `
  -e API_KEY="your-api-key-here" `
  -e ENDPOINT_URL="https://cortex.example.com/api/upload/sarif" `
  imed-cortex-action:latest
```

## Security Considerations

- **Never commit API keys**: Always use GitHub Secrets for the `api_key` input
- **Never commit .env file**: The `.env` file is in `.gitignore` to prevent accidental commits
- **Use .env.example**: Share `.env.example` with placeholder values, never the actual `.env`
- **Use environment variables**: Store the endpoint URL in GitHub Variables or Secrets
- **Validate reports**: The action validates that the report file exists before attempting upload
- **Secure transmission**: All data is transmitted over HTTPS to the Imed Cortex platform

## Troubleshooting

### Upload fails with "Report file not found"
- Ensure the `report_path` is correct and the file exists
- Check that your security scanner successfully created the output file
- Verify the path is relative to the GitHub workspace

### Upload fails with authentication error
- Verify your API key is correct and not expired
- Check that the API key has proper permissions in Imed Cortex
- Ensure the API key secret is properly configured in your repository

### Network or connection errors
- Verify the `endpoint_url` is correct and accessible
- Check if there are any network restrictions or firewall rules
- Ensure the Imed Cortex platform is operational

## Development

### Project Structure

```
.
├── Dockerfile              # Docker image definition
├── entrypoint.sh          # Main script that handles upload
├── action.yml             # GitHub Action metadata
├── test.sh                # Bash test script
├── test.ps1               # PowerShell test script
└── README.md              # This file
```

### Building Locally

```bash
docker build -t imed-cortex-action:latest .
```

### Running Tests

1. Configure your test environment:
   ```bash
   cp .env.example .env
   # Edit .env with your test values
   ```

2. Run the test script:
   ```bash
   # Bash
   ./test.sh

   # PowerShell
   ./test.ps1
   ```

The test scripts will automatically load configuration from `.env` and validate all required values.

## Contributing

Contributions are welcome! Please ensure:
- All scripts follow POSIX sh compatibility (for `entrypoint.sh`)
- Test scripts are updated for both Bash and PowerShell
- Documentation is updated to reflect changes
- Docker builds successfully without warnings

## License

[Your License Here]

## Support

For issues, questions, or contributions, please contact the Imed Cortex team or open an issue in this repository.
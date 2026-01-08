# Imed Cortex Action

A GitHub Action that uploads security scan reports to the Imed Cortex platform. This action provides a simple interface for integrating security scanning into your CI/CD pipeline.

## Overview

This action is designed to work with various security scanning tools (Trivy, Gitleaks, etc.) and automatically uploads their reports to the Imed Cortex platform for centralized security analysis and reporting.

## Features

- 🔒 Secure API key-based authentication
- 📤 Automatic report upload to Imed Cortex
- ✅ Built-in validation of inputs
- 🔍 Detailed error reporting
- 🐳 Docker-based implementation for consistency

## Usage

### Basic Example

```yaml
name: Security Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  scan-and-upload:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Trivy security scan
        run: |
          docker run --rm \
            -v ${{ github.workspace }}:/workspace \
            aquasec/trivy:latest \
            fs --format json --output /workspace/trivy-report.json /workspace

      - name: Upload to Imed Cortex
        uses: cguajardo-imed/cortex-action@v1
        with:
          endpoint_url: https://cortex.example.com/api/reports/upload
          api_key: ${{ secrets.CORTEX_API_KEY }}
          report_path: trivy-report.json
```

### Using GitHub Variables

```yaml
      - name: Upload to Imed Cortex
        uses: cguajardo-imed/cortex-action@v1
        with:
          endpoint_url: ${{ vars.CORTEX_ENDPOINT_URL }}
          api_key: ${{ secrets.CORTEX_API_KEY }}
          report_path: scan-results.json
```

### Multiple Scanners Example

```yaml
name: Security Scans

on:
  push:
    branches: [ main ]

jobs:
  trivy-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Trivy
        run: |
          docker run --rm -v ${{ github.workspace }}:/workspace \
            aquasec/trivy:latest fs --format json \
            --output /workspace/trivy-results.json /workspace
      
      - name: Upload Trivy Report
        uses: cguajardo-imed/cortex-action@v1
        with:
          endpoint_url: ${{ vars.CORTEX_ENDPOINT_URL }}
          api_key: ${{ secrets.CORTEX_API_KEY }}
          report_path: trivy-results.json

  gitleaks-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Run Gitleaks
        run: |
          docker run --rm -v ${{ github.workspace }}:/workspace \
            zricethezav/gitleaks:latest detect \
            --source /workspace --report-path /workspace/gitleaks-report.json \
            --report-format json || true
      
      - name: Upload Gitleaks Report
        uses: cguajardo-imed/cortex-action@v1
        with:
          endpoint_url: ${{ vars.CORTEX_ENDPOINT_URL }}
          api_key: ${{ secrets.CORTEX_API_KEY }}
          report_path: gitleaks-report.json
```

### With Error Handling

```yaml
      - name: Upload to Imed Cortex
        id: cortex-upload
        uses: cguajardo-imed/cortex-action@v1
        with:
          endpoint_url: ${{ vars.CORTEX_ENDPOINT_URL }}
          api_key: ${{ secrets.CORTEX_API_KEY }}
          report_path: scan-results.json

      - name: Check Upload Status
        if: steps.cortex-upload.outputs.success == 'false'
        run: |
          echo "Upload failed: ${{ steps.cortex-upload.outputs.message }}"
          exit 1
```

## Inputs

### Required Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `endpoint_url` | Full endpoint URL for Imed Cortex | Yes |
| `api_key` | API key for authentication | Yes |
| `report_path` | Path to the security scan report file | Yes |

## Outputs

| Output | Description |
|--------|-------------|
| `success` | Indicates if report upload was successful (true/false) |
| `message` | Detailed message about the upload result |

## Setup

### 1. Get Your API Key

Contact your Imed Cortex administrator to obtain an API key for your organization.

### 2. Configure Secrets

Add your API key as a secret in your GitHub repository:

1. Go to your repository **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `CORTEX_API_KEY`
4. Value: Your API key
5. Click **Add secret**

### 3. Configure Variables (Optional)

For the endpoint URL, you can use repository variables:

1. Go to your repository **Settings** → **Secrets and variables** → **Actions** → **Variables** tab
2. Click **New repository variable**
3. Name: `CORTEX_ENDPOINT_URL`
4. Value: Your Cortex endpoint URL (e.g., `https://cortex.example.com/api/reports/upload`)
5. Click **Add variable**

## Supported Security Scanners

This action accepts reports from various security scanning tools. Common examples include:

- **Trivy** - Container and filesystem vulnerability scanner
- **Gitleaks** - Secret detection tool
- **SARIF** - Static Analysis Results Interchange Format
- Any tool that generates JSON or compatible report formats

## Troubleshooting

### Upload Failed: Authentication Error

**Problem:** Getting 401 or 403 errors

**Solution:**
- Verify your API key is correct
- Check that the secret name matches in your workflow
- Ensure your API key hasn't expired

### Upload Failed: Connection Error

**Problem:** Cannot connect to endpoint

**Solution:**
- Verify the endpoint URL is correct
- Ensure network connectivity to the Cortex platform

### Upload Failed: Report File Not Found

**Problem:** Report file not found at specified path

**Solution:**
- Verify the scanner actually created the report file
- Check the `report_path` matches the scanner output location
- Ensure the path is relative to the workspace root

### Debug Mode

For detailed troubleshooting, you can enable debug logging by setting the `ACTIONS_STEP_DEBUG` secret to `true` in your repository settings.

## Example Workflows

### Continuous Scanning

```yaml
name: Continuous Security Scan

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    # Run daily at 2 AM UTC
    - cron: '0 2 * * *'

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Security Scan
        run: |
          docker run --rm -v ${{ github.workspace }}:/workspace \
            aquasec/trivy:latest fs --format json \
            --output /workspace/trivy-report.json /workspace

      - name: Upload to Cortex
        uses: cguajardo-imed/cortex-action@v1
        with:
          endpoint_url: ${{ vars.CORTEX_ENDPOINT_URL }}
          api_key: ${{ secrets.CORTEX_API_KEY }}
          report_path: trivy-report.json
```

### Matrix Strategy (Multiple Scanners)

```yaml
name: Multi-Scanner Security Analysis

on:
  push:
    branches: [ main ]

jobs:
  scan:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        scanner:
          - name: trivy
            command: docker run --rm -v ${{ github.workspace }}:/workspace aquasec/trivy:latest fs --format json --output /workspace/trivy.json /workspace
            report: trivy.json
          - name: gitleaks
            command: docker run --rm -v ${{ github.workspace }}:/workspace zricethezav/gitleaks:latest detect --source /workspace --report-path /workspace/gitleaks.json --report-format json || true
            report: gitleaks.json
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run ${{ matrix.scanner.name }}
        run: ${{ matrix.scanner.command }}

      - name: Upload ${{ matrix.scanner.name }} Report
        uses: cguajardo-imed/cortex-action@v1
        with:
          endpoint_url: ${{ vars.CORTEX_ENDPOINT_URL }}
          api_key: ${{ secrets.CORTEX_API_KEY }}
          report_path: ${{ matrix.scanner.report }}
```

## Security Considerations

- **API Key Storage**: Always store API keys in GitHub Secrets, never in code
- **Endpoint URL**: Can be stored in Variables for easier management
- **Report Contents**: Ensure reports don't contain sensitive information
- **Access Control**: Limit who can view workflow runs that contain security data

## Support

For issues, questions, or feature requests:

1. Check the [troubleshooting section](#troubleshooting) above
2. Review existing [GitHub Issues](https://github.com/cguajardo-imed/cortex-action/issues)
3. Create a new issue with detailed information about your problem

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Related

- [cortex-uploader](https://github.com/cguajardo-imed/cortex-uploader) - The underlying Docker container
- Docker Image: `ghcr.io/cguajardo-imed/cortex-uploader:latest`

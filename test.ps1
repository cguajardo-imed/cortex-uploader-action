#!/usr/bin/env pwsh

# Function to load .env file
function Import-EnvFile
{
    param (
        [string]$EnvFilePath = ".env"
    )

    if (-not (Test-Path $EnvFilePath))
    {
        Write-Host "ERROR: .env file not found!" -ForegroundColor Red
        Write-Host "Please copy .env.example to .env and configure your settings."
        exit 1
    }

    Write-Host "Loading configuration from .env file..."

    Get-Content $EnvFilePath | ForEach-Object {
        $line = $_.Trim()

        # Skip empty lines and comments
        if ($line -eq "" -or $line.StartsWith("#"))
        {
            return
        }

        # Parse KEY=VALUE
        if ($line -match '^([^=]+)=(.*)$')
        {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()

            # Remove quotes if present
            if ($value.StartsWith('"') -and $value.EndsWith('"'))
            {
                $value = $value.Substring(1, $value.Length - 2)
            } elseif ($value.StartsWith("'") -and $value.EndsWith("'"))
            {
                $value = $value.Substring(1, $value.Length - 2)
            }

            # Set environment variable
            Set-Variable -Name $key -Value $value -Scope Script
            Write-Host "  Loaded: $key" -ForegroundColor Gray
        }
    }
}

# Load environment variables from .env file
Import-EnvFile

# Validate required variables
if ([string]::IsNullOrEmpty($REPORT_PATH))
{
    Write-Host "ERROR: REPORT_PATH is not set in .env file" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($ENDPOINT_URL))
{
    Write-Host "ERROR: ENDPOINT_URL is not set in .env file" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($API_KEY))
{
    Write-Host "ERROR: API_KEY is not set in .env file" -ForegroundColor Red
    exit 1
}

# Set default image name if not provided
if ([string]::IsNullOrEmpty($IMAGE_NAME))
{
    $IMAGE_NAME = "imed-cortex-action:latest"
}

$IMAGE_IS_BUILT = 0

# First check if docker image is already built
try
{
    $null = docker image inspect $IMAGE_NAME 2>$null
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host "ImedCortexAction Docker image already exists."
        # $IMAGE_IS_BUILT = 1
    }
} catch
{
    # Image does not exist
}

if ($IMAGE_IS_BUILT -eq 0)
{
    Write-Host "Building ImedCortexAction Docker image..."
    docker build -t $IMAGE_NAME .
    if ($LASTEXITCODE -ne 0)
    {
        Write-Host "ERROR: Docker build failed" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Uploading report from $REPORT_PATH"
docker run -v "${REPORT_PATH}:/github/workspace/report.json" `
    -e REPORT_PATH="/github/workspace/report.json" `
    -e API_KEY="$API_KEY" `
    -e ENDPOINT_URL="$ENDPOINT_URL" `
    $IMAGE_NAME

if ($LASTEXITCODE -ne 0)
{
    Write-Host "ERROR: Docker run failed" -ForegroundColor Red
    exit 1
}

Write-Host "Upload completed successfully!" -ForegroundColor Green

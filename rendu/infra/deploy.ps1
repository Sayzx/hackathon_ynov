###############################################################################
# 🚀 Phi-3.5-Financial Infrastructure Deployment Script (Windows/PowerShell)
# Purpose: Deploy Ollama + Phi-3.5-Financial using Docker on Windows
# Requirements: Docker Desktop, PowerShell 5.0+, Git (optional)
###############################################################################

param(
    [ValidateSet("install", "start", "stop", "restart", "status", "health-check", "test", "clean", "logs")]
    [string]$Action = "install",
    [switch]$NoWait = $false
)

# Configuration
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$COMPOSE_FILE = Join-Path $SCRIPT_DIR "docker-compose.yml"
$DOCKERFILE = Join-Path $SCRIPT_DIR "Dockerfile"
$MODELFILE = Join-Path $SCRIPT_DIR "Modelfile"
$INIT_SCRIPT = Join-Path $SCRIPT_DIR "init-model.sh"

$API_URL = "http://localhost:11434"
$CONTAINER_NAME = "phi-financial-ollama"
$MODEL_NAME = "phi-financial"

# Colors
$Colors = @{
    Green = [System.ConsoleColor]::Green
    Red = [System.ConsoleColor]::Red
    Yellow = [System.ConsoleColor]::Yellow
    Blue = [System.ConsoleColor]::Cyan
    Reset = $null
}

function Write-Success {
    param([string]$Message)
    Write-Host "[✓] " -ForegroundColor $Colors.Green -NoNewline
    Write-Host $Message
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[✗] " -ForegroundColor $Colors.Red -NoNewline
    Write-Host $Message -ForegroundColor $Colors.Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[!] " -ForegroundColor $Colors.Yellow -NoNewline
    Write-Host $Message -ForegroundColor $Colors.Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "[→] " -ForegroundColor $Colors.Blue -NoNewline
    Write-Host $Message
}

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Colors.Blue
    Write-Host $Message -ForegroundColor $Colors.Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Colors.Blue
    Write-Host ""
}

###############################################################################
# Prerequisites Check
###############################################################################

function Check-Prerequisites {
    Write-Header "Checking Prerequisites"

    # Check Docker
    Write-Info "Checking Docker..."
    try {
        $dockerVersion = docker --version
        Write-Success "Docker installed: $dockerVersion"
    } catch {
        Write-Error-Custom "Docker not found. Install Docker Desktop for Windows"
        Write-Info "Download: https://www.docker.com/products/docker-desktop"
        exit 1
    }

    # Check Docker Compose
    Write-Info "Checking Docker Compose..."
    try {
        $composeVersion = docker-compose --version
        Write-Success "Docker Compose installed: $composeVersion"
    } catch {
        Write-Error-Custom "Docker Compose not found"
        Write-Info "Docker Compose comes with Docker Desktop"
        exit 1
    }

    # Check required files
    Write-Info "Checking required files..."
    $requiredFiles = @($COMPOSE_FILE, $DOCKERFILE, $MODELFILE, $INIT_SCRIPT)
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            Write-Error-Custom "Required file not found: $file"
            exit 1
        }
    }
    Write-Success "All required files present"

    Write-Success "All prerequisites met`n"
}

###############################################################################
# Helper Functions
###############################################################################

function Wait-ForAPI {
    param([int]$MaxRetries = 60, [int]$DelaySeconds = 2)

    Write-Info "Waiting for API to be ready..."
    $retries = 0

    while ($retries -lt $MaxRetries) {
        try {
            $response = Invoke-WebRequest -Uri "$API_URL/api/tags" -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Success "API is ready"
                return $true
            }
        } catch {
            # API not ready yet
        }

        $retries++
        if ($retries % 10 -eq 0) {
            Write-Host "." -ForegroundColor $Colors.Yellow -NoNewline
        }
        Start-Sleep -Seconds $DelaySeconds
    }

    Write-Error-Custom "API failed to start after $($MaxRetries * $DelaySeconds) seconds"
    return $false
}

###############################################################################
# Actions
###############################################################################

function Action-Install {
    Write-Header "Installing Phi-3.5-Financial Infrastructure"

    # Build image
    Write-Info "Building Docker image..."
    docker-compose build --no-cache

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Docker build failed"
        exit 1
    }
    Write-Success "Image built successfully"

    # Start container
    Write-Info "Starting container..."
    docker-compose up -d

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to start container"
        exit 1
    }
    Write-Success "Container started"

    # Wait for API
    if (-not (Wait-ForAPI)) {
        exit 1
    }

    # Initialize model
    Write-Info "Initializing Phi-3.5-Financial model..."
    docker-compose exec -T ollama /usr/local/bin/init-model.sh

    Write-Header "✅ INSTALLATION COMPLETE"
    Display-Summary
}

function Action-Start {
    Write-Header "Starting Containers"

    docker-compose up -d

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Containers started"
        Wait-ForAPI | Out-Null
        Write-Success "API is ready"
    } else {
        Write-Error-Custom "Failed to start containers"
        exit 1
    }
}

function Action-Stop {
    Write-Header "Stopping Containers"

    docker-compose stop

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Containers stopped"
    } else {
        Write-Error-Custom "Failed to stop containers"
        exit 1
    }
}

function Action-Restart {
    Write-Header "Restarting Containers"

    Action-Stop
    Start-Sleep -Seconds 2
    Action-Start
}

function Action-Status {
    Write-Header "Service Status"

    Write-Info "Container Status:"
    docker-compose ps

    Write-Host ""
    Write-Info "API Health:"
    try {
        $response = Invoke-WebRequest -Uri "$API_URL/api/tags" -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Success "API is responding"
            $models = $response.Content | ConvertFrom-Json
            if ($models.models) {
                Write-Host "Available models:"
                $models.models | ForEach-Object { Write-Host "  • $($_.name)" -ForegroundColor $Colors.Green }
            }
        } else {
            Write-Error-Custom "API is not responding"
        }
    } catch {
        Write-Error-Custom "API is not responding"
    }
}

function Action-HealthCheck {
    Write-Header "Health Check"

    Write-Info "Checking server connectivity..."
    try {
        $response = Invoke-WebRequest -Uri "$API_URL/api/tags" -ErrorAction SilentlyContinue
        Write-Success "Server is responding"
    } catch {
        Write-Error-Custom "Server is not responding at $API_URL"
        exit 1
    }

    Write-Info "Checking model availability..."
    try {
        $response = Invoke-WebRequest -Uri "$API_URL/api/tags" -ErrorAction SilentlyContinue
        $models = $response.Content | ConvertFrom-Json
        if ($models.models | Where-Object { $_.name -eq $MODEL_NAME }) {
            Write-Success "Model '$MODEL_NAME' is available"
        } else {
            Write-Warning-Custom "Model '$MODEL_NAME' not found"
        }
    } catch {
        Write-Error-Custom "Failed to check models"
    }

    Write-Host ""
    Write-Success "✓ Health check complete"
}

function Action-Test {
    Write-Header "Testing API"

    Write-Info "Sending test prompt..."
    try {
        $body = @{
            model = $MODEL_NAME
            prompt = "What is finance?"
            stream = $false
        } | ConvertTo-Json

        $response = Invoke-WebRequest -Uri "$API_URL/api/generate" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -TimeoutSec 60 `
            -ErrorAction SilentlyContinue

        if ($response.StatusCode -eq 200) {
            Write-Success "API test successful"
            $data = $response.Content | ConvertFrom-Json
            Write-Host ""
            Write-Host "Response:" -ForegroundColor $Colors.Green
            Write-Host ($data.response -split '\n' | Select-Object -First 5 | Join-String -Separator "`n")
            Write-Host "..."
        } else {
            Write-Error-Custom "API test failed"
        }
    } catch {
        Write-Error-Custom "API test failed: $_"
    }
}

function Action-Logs {
    Write-Header "Container Logs"
    docker-compose logs -f ollama
}

function Action-Clean {
    Write-Host "WARNING: This will remove containers and data!" -ForegroundColor $Colors.Red
    $confirmation = Read-Host "Continue? (y/N)"

    if ($confirmation -eq "y" -or $confirmation -eq "Y") {
        Write-Info "Removing containers and volumes..."
        docker-compose down -v

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Cleanup complete"
        } else {
            Write-Error-Custom "Cleanup failed"
            exit 1
        }
    } else {
        Write-Info "Cleanup cancelled"
    }
}

function Display-Summary {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor $Colors.Green
    Write-Host "║         Phi-3.5-Financial Infrastructure Ready            ║" -ForegroundColor $Colors.Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor $Colors.Green
    Write-Host ""
    Write-Host "📊 Service Information:" -ForegroundColor $Colors.Blue
    Write-Host "  • Server:       Ollama (Docker)"
    Write-Host "  • Model:        $MODEL_NAME"
    Write-Host "  • API URL:      $API_URL"
    Write-Host ""
    Write-Host "📡 API Endpoints:" -ForegroundColor $Colors.Blue
    Write-Host "  • Generate:     POST $API_URL/api/generate"
    Write-Host "  • List Models:  GET  $API_URL/api/tags"
    Write-Host ""
    Write-Host "🚀 Next Steps:" -ForegroundColor $Colors.Blue
    Write-Host "  1. DEV WEB team: Connect to $API_URL"
    Write-Host "  2. Run 'deploy.ps1 -Action health-check' to verify"
    Write-Host "  3. Run 'deploy.ps1 -Action test' to test API"
    Write-Host ""
    Write-Host "📚 Documentation:" -ForegroundColor $Colors.Blue
    Write-Host "  See: .\README.md"
    Write-Host ""
}

###############################################################################
# Main Entry Point
###############################################################################

function Main {
    Clear-Host

    Write-Host ""
    Write-Host " ____  _     _     _ ___   __   ____  _   _   _   _   _   _   _   _" -ForegroundColor $Colors.Blue
    Write-Host "|  _ \| |   (_)   | |___) (  ) (  ___)|  | | | | | |_| | | | | |_| |" -ForegroundColor $Colors.Blue
    Write-Host "| |_)| |    | | | | |__     ||  |__  |  |_| |  \ /  | | | |_| | |   |" -ForegroundColor $Colors.Blue
    Write-Host "|  __/| |   | | | | |  ___) ||  __) |  \_/    \_/   |_| |__   | |   |" -ForegroundColor $Colors.Blue
    Write-Host "| |   | |___| |  \| | |____) (( (___  |          Financial| |_| |   |" -ForegroundColor $Colors.Blue
    Write-Host "|_|   |_____|_|_/\_| |_____ / \ ____|" -ForegroundColor $Colors.Blue
    Write-Host ""
    Write-Host "═════════════════════════════════════════════════════════════════════════════" -ForegroundColor $Colors.Blue
    Write-Host "  🚀 Phi-3.5-Financial Infrastructure Deployment (Docker)" -ForegroundColor $Colors.Blue
    Write-Host "  TechCorp Industries Hackathon - Windows/PowerShell Edition" -ForegroundColor $Colors.Blue
    Write-Host "═════════════════════════════════════════════════════════════════════════════" -ForegroundColor $Colors.Blue
    Write-Host ""

    switch ($Action) {
        "install" { Check-Prerequisites; Action-Install }
        "start" { Action-Start }
        "stop" { Action-Stop }
        "restart" { Action-Restart }
        "status" { Action-Status }
        "health-check" { Action-HealthCheck }
        "test" { Action-Test }
        "clean" { Action-Clean }
        "logs" { Action-Logs }
        default {
            Write-Error-Custom "Unknown action: $Action"
            Write-Host ""
            Write-Host "Available actions:"
            Write-Host "  install      - Install and start (default)"
            Write-Host "  start        - Start containers"
            Write-Host "  stop         - Stop containers"
            Write-Host "  restart      - Restart containers"
            Write-Host "  status       - Show service status"
            Write-Host "  health-check - Run health check"
            Write-Host "  test         - Test API"
            Write-Host "  logs         - Show container logs"
            Write-Host "  clean        - Remove containers and data"
            exit 1
        }
    }
}

# Run main
& Main

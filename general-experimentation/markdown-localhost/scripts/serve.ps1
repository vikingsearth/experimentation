# Serve the markdown-localhost experiment
# Usage: .\scripts\serve.ps1

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $ProjectDir

# Install docsify-cli if not already installed
try {
    npx docsify --version 2>&1 | Out-Null
} catch {
    Write-Host "Installing docsify-cli..."
    npm install
}

Write-Host ""
Write-Host "Starting Docsify server..."
Write-Host "Open http://localhost:3000 in your browser"
Write-Host "Press Ctrl+C to stop"
Write-Host ""

npx docsify serve content --port 3000 --open

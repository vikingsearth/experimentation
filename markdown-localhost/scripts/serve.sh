#!/bin/bash
# Serve the markdown-localhost experiment
# Usage: bash scripts/serve.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Install docsify-cli if not already installed
if ! npx docsify --version > /dev/null 2>&1; then
  echo "Installing docsify-cli..."
  npm install
fi

echo ""
echo "Starting Docsify server..."
echo "Open http://localhost:3000 in your browser"
echo "Press Ctrl+C to stop"
echo ""

npx docsify serve content --port 3000 --open

#!/bin/bash
#
# INSTALLATION SCRIPT
# Sets up benchmarking environment

echo "Setting up LLM benchmarking environment..."

# Check for dependencies
command -v bc >/dev/null 2>&1 || { echo "Installing bc..."; sudo apt-get update && sudo apt-get install -y bc; }
command -v ollama >/dev/null 2>&1 || { echo "Ollama not found. Please install Ollama first."; exit 1; }

# Make all scripts executable
chmod +x main.sh config.sh helpers.sh download_models.sh run_benchmarks.sh generate_reports.sh display_summary.sh

echo "Setup complete. Run ./main.sh to start benchmarking."

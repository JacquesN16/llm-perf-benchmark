#!/bin/bash
#
# MAIN BENCHMARK SCRIPT
# Orchestrates the LLM benchmarking process

# Source configuration and helper functions
source "config.sh"
source "helpers.sh"

# Create results directory and initialize
init_benchmark

# Check Ollama installation
if ! command -v ollama &> /dev/null; then
    echo "Error: Ollama is not installed. Please install it first."
    exit 1
fi

# Download models
print_header "DOWNLOADING MODELS"
source "download_models.sh"

# Run benchmarks
print_header "STARTING BENCHMARKS"
echo "Results will be saved to $RESULTS_DIR"
source "run_benchmarks.sh"

# Generate reports
print_header "GENERATING REPORTS"
source "generate_reports.sh"

# Display summary
print_header "BENCHMARK COMPLETE"
source "display_summary.sh"

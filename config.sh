#!/bin/bash
#
# CONFIGURATION SETTINGS
# Define models, prompts and other settings

# Models to benchmark
MODELS=(
  "llama2:7b-q4_0"
  "llama3:8b-q4_0"
  "mistral:7b-q4_0"
  "phi"
  "tinyllama"
  "deepseek-coder:6.7b"
)

# Number of tokens to generate for each test
NUM_TOKENS=200

# Test prompts of varying complexity
PROMPTS=(
  "Explain the concept of artificial intelligence in one paragraph."
  "Write a short story about a robot that develops emotions."
  "Solve this math problem: If a train travels at 120 km/h and another train travels at 80 km/h in the opposite direction, how long will it take for them to be 500 km apart if they start 100 km apart?"
  "Explain quantum computing to a high school student."
)

# Create timestamped results directory
RESULTS_DIR="ollama_benchmarks_$(date +%Y%m%d_%H%M%S)"

# CSV for storing results
RESULTS_CSV="$RESULTS_DIR/benchmark_results.csv"

# HTML report path
HTML_REPORT="$RESULTS_DIR/benchmark_report.html"

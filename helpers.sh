#!/bin/bash
#
# HELPER FUNCTIONS
# Utility functions used across the benchmark scripts

# Initialize benchmark environment
init_benchmark() {
  mkdir -p "$RESULTS_DIR"
  echo "Model,Prompt,Tokens,Generation_Time_Seconds,Tokens_Per_Second,Max_Memory_MB" > "$RESULTS_CSV"
}

# Get memory usage of Ollama process in MB
get_memory_usage() {
  ps -o rss= -p $(pgrep ollama) | awk '{print $1/1024}'
}

# Display a progress bar
show_progress() {
  local current=$1
  local total=$2
  local prefix=$3
  local size=30
  local filled=$(( current * size / total ))
  local empty=$(( size - filled ))

  printf "\r%s [%s%s] %d/%d" "$prefix" \
         "$(printf "%${filled}s" | tr ' ' '#')" \
         "$(printf "%${empty}s" | tr ' ' '.')" \
         "$current" "$total"
}

# Print a section header
print_header() {
  echo ""
  echo "===== $1 ====="
  echo ""
}

# Clean model name for filenames
sanitize_name() {
  echo "${1//[:\/]/_}"
}

# Clear cache for fair comparison
clear_cache() {
  sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1
}

#!/bin/bash

# LLM Benchmarking Script for CPU-only systems
# This script benchmarks multiple Ollama models for inference speed and memory usage

# Models to benchmark
MODELS=("llama2:7b-q4_0" "llama3:8b-q4_0" "mistral:7b-q4_0" "phi" "tinyllama" "deepseek-coder:6.7b")

# Test prompts of varying complexity
declare -a PROMPTS=(
  "Explain the concept of artificial intelligence in one paragraph."
  "Write a short story about a robot that develops emotions."
  "Solve this math problem: If a train travels at 120 km/h and another train travels at 80 km/h in the opposite direction, how long will it take for them to be 500 km apart if they start 100 km apart?"
  "Explain quantum computing to a high school student."
)

# Create results directory
RESULTS_DIR="ollama_benchmarks_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

# CSV for storing results
RESULTS_CSV="$RESULTS_DIR/benchmark_results.csv"
echo "Model,Prompt,Tokens,Generation_Time_Seconds,Tokens_Per_Second,Max_Memory_MB" > "$RESULTS_CSV"

# Function to get memory usage of Ollama process
get_memory_usage() {
  # Get RSS memory in kilobytes and convert to MB
  ps -o rss= -p $(pgrep ollama) | awk '{print $1/1024}'
}

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "Error: Ollama is not installed. Please install it first."
    exit 1
fi

# Pull all models first
echo "========== Downloading models =========="
for model in "${MODELS[@]}"; do
  echo "Pulling $model..."
  ollama pull "$model"
done

echo "========== Starting benchmarks =========="
echo "Results will be saved to $RESULTS_DIR"

# Benchmark each model with each prompt
for model in "${MODELS[@]}"; do
  echo "Testing model: $model"

  # Number of tokens to generate
  NUM_TOKENS=200

  for prompt_idx in "${!PROMPTS[@]}"; do
    prompt="${PROMPTS[$prompt_idx]}"
    prompt_short="${prompt:0:30}..."
    echo "  Prompt $((prompt_idx+1)): $prompt_short"

    # Clear cache between runs
    echo "  Clearing cache..."
    sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1

    # Start memory monitoring in background
    memory_file="$RESULTS_DIR/${model//[:\/]/_}_prompt_${prompt_idx}_memory.txt"
    (
      while true; do
        mem=$(get_memory_usage)
        echo "$mem" >> "$memory_file"
        sleep 0.5
      done
    ) & MEMORY_PID=$!

    # Run benchmark with timing
    output_file="$RESULTS_DIR/${model//[:\/]/_}_prompt_${prompt_idx}_output.txt"

    # Measure time
    TIMEFORMAT=%R
    start_time=$(date +%s.%N)

    # Run model and capture output
    ollama run "$model" --num-predict $NUM_TOKENS "$prompt" > "$output_file" 2>&1

    end_time=$(date +%s.%N)

    # Kill memory monitoring
    kill $MEMORY_PID 2>/dev/null

    # Calculate metrics
    time_taken=$(echo "$end_time - $start_time" | bc)
    tokens_per_second=$(echo "$NUM_TOKENS / $time_taken" | bc -l)

    # Get max memory usage
    max_memory=$(sort -n "$memory_file" | tail -n 1)
    if [ -z "$max_memory" ]; then
      max_memory="N/A"
    fi

    # Save results to CSV
    echo "$model,\"${prompt:0:50}...\",$NUM_TOKENS,$time_taken,$tokens_per_second,$max_memory" >> "$RESULTS_CSV"

    echo "    Time: ${time_taken}s, Speed: ${tokens_per_second} tokens/s, Max Memory: ${max_memory}MB"

    # Short pause between prompts
    sleep 2
  done

  echo ""
done

# Generate HTML report
HTML_REPORT="$RESULTS_DIR/benchmark_report.html"
cat > "$HTML_REPORT" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Ollama LLM Benchmark Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .model-header { background-color: #e6f7ff; font-weight: bold; }
        h1, h2 { color: #333; }
    </style>
</head>
<body>
    <h1>Ollama LLM Benchmark Results</h1>
    <p>Date: $(date)</p>
    <p>System: $(uname -a)</p>
    <p>CPU: $(grep "model name" /proc/cpuinfo | head -n 1 | cut -d ":" -f 2 | sed 's/^[ \t]*//')</p>
    <p>Memory: $(free -h | grep Mem | awk '{print $2}')</p>

    <h2>Performance Summary</h2>
    <table id="summary">
        <tr>
            <th>Model</th>
            <th>Avg Tokens/Second</th>
            <th>Avg Memory (MB)</th>
        </tr>
EOF

# Generate summary data
for model in "${MODELS[@]}"; do
  avg_tps=$(grep "$model" "$RESULTS_CSV" | cut -d ',' -f 5 | awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; else print "N/A"; }')
  avg_memory=$(grep "$model" "$RESULTS_CSV" | cut -d ',' -f 6 | awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; else print "N/A"; }')

  echo "<tr><td>$model</td><td>$(printf "%.2f" $avg_tps)</td><td>$(printf "%.2f" $avg_memory)</td></tr>" >> "$HTML_REPORT"
done

# Complete the HTML file
cat >> "$HTML_REPORT" << EOF
    </table>

    <h2>Detailed Results</h2>
    <table id="details">
        <tr>
            <th>Model</th>
            <th>Prompt</th>
            <th>Tokens</th>
            <th>Time (s)</th>
            <th>Tokens/Second</th>
            <th>Max Memory (MB)</th>
        </tr>
EOF

# Add all benchmark data to the HTML report
tail -n +2 "$RESULTS_CSV" | while IFS=, read -r model prompt tokens time tps memory; do
  echo "<tr><td>$model</td><td>$prompt</td><td>$tokens</td><td>$(printf "%.2f" $time)</td><td>$(printf "%.2f" $tps)</td><td>$memory</td></tr>" >> "$HTML_REPORT"
done

# Finish HTML
cat >> "$HTML_REPORT" << EOF
    </table>
</body>
</html>
EOF

# Print final message
echo "========== Benchmark complete =========="
echo "Results saved to:"
echo "- CSV: $RESULTS_CSV"
echo "- HTML Report: $HTML_REPORT"
echo "- Raw outputs in $RESULTS_DIR"
echo ""
echo "Summary of results:"
echo "-----------------------"
awk -F, 'NR>1 {models[$1]++; tps[$1]+=$5; mem[$1]+=$6}
    END {
        printf "%-15s %-15s %-15s\n", "Model", "Avg Tokens/sec", "Avg Memory (MB)";
        for (model in models) {
            printf "%-15s %-15.2f %-15.2f\n", model, tps[model]/models[model], mem[model]/models[model]
        }
    }' "$RESULTS_CSV"

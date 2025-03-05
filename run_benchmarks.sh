#!/bin/bash
#
# RUN BENCHMARKS
# Executes benchmark tests for all models and prompts

# Calculate total benchmarks for progress tracking
TOTAL_BENCHMARKS=$(( ${#MODELS[@]} * ${#PROMPTS[@]} ))
CURRENT_BENCHMARK=0

# Benchmark each model with each prompt
for model in "${MODELS[@]}"; do
  echo ""
  echo "Testing model: $model"
  echo "----------------------------------------"

  for prompt_idx in "${!PROMPTS[@]}"; do
    prompt="${PROMPTS[$prompt_idx]}"
    prompt_short="${prompt:0:30}..."
    echo "  Prompt $((prompt_idx+1)): $prompt_short"

    # Clear cache between runs
    echo "    Clearing cache..."
    clear_cache

    # Sanitize model name for filenames
    safe_model_name=$(sanitize_name "$model")

    # Files for storing benchmark data
    memory_file="$RESULTS_DIR/${safe_model_name}_prompt_${prompt_idx}_memory.txt"
    output_file="$RESULTS_DIR/${safe_model_name}_prompt_${prompt_idx}_output.txt"

    # Start memory monitoring in background
    (
      while true; do
        mem=$(get_memory_usage)
        echo "$mem" >> "$memory_file"
        sleep 0.5
      done
    ) & MEMORY_PID=$!

    # Measure generation time
    echo "    Running inference..."
    start_time=$(date +%s.%N)

    # Run model inference
    ollama run "$model" --num-predict $NUM_TOKENS "$prompt" > "$output_file" 2>&1

    end_time=$(date +%s.%N)

    # Stop memory monitoring
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

    # Display results
    echo "    Results:"
    printf "      %-20s %s\n" "Time:" "$(printf "%.2f" $time_taken) seconds"
    printf "      %-20s %s\n" "Speed:" "$(printf "%.2f" $tokens_per_second) tokens/sec"
    printf "      %-20s %s\n" "Max Memory:" "${max_memory}MB"

    # Update progress
    CURRENT_BENCHMARK=$((CURRENT_BENCHMARK+1))
    show_progress "$CURRENT_BENCHMARK" "$TOTAL_BENCHMARKS" "Overall progress"

    # Short pause between prompts
    sleep 2
  done
done
echo -e "\n"

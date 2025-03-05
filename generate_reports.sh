#!/bin/bash
#
# GENERATE REPORTS
# Creates HTML and summary reports from benchmark data

# Create HTML report header
cat > "$HTML_REPORT" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Ollama LLM Benchmark Results</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            line-height: 1.5;
            color: #333;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 20px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        th, td {
            border: 1px solid #ddd;
            padding: 10px;
            text-align: left;
        }
        th {
            background-color: #4CAF50;
            color: white;
            font-weight: bold;
        }
        tr:nth-child(even) { background-color: #f5f5f5; }
        tr:hover { background-color: #f0f0f0; }
        .model-header {
            background-color: #e6f7ff;
            font-weight: bold;
        }
        h1, h2 {
            color: #2e7d32;
            border-bottom: 2px solid #2e7d32;
            padding-bottom: 5px;
        }
        .system-info {
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .best-result {
            font-weight: bold;
            color: #2e7d32;
        }
    </style>
</head>
<body>
    <h1>Ollama LLM Benchmark Results</h1>

    <div class="system-info">
        <h3>System Information</h3>
        <p><strong>Date:</strong> $(date)</p>
        <p><strong>System:</strong> $(uname -a)</p>
        <p><strong>CPU:</strong> $(grep "model name" /proc/cpuinfo | head -n 1 | cut -d ":" -f 2 | sed 's/^[ \t]*//')</p>
        <p><strong>Memory:</strong> $(free -h | grep Mem | awk '{print $2}')</p>
    </div>

    <h2>Performance Summary</h2>
    <table id="summary">
        <tr>
            <th>Model</th>
            <th>Avg Tokens/Second</th>
            <th>Avg Memory (MB)</th>
        </tr>
EOF

# Generate summary data
declare -A model_tps_sum model_mem_sum model_count
declare -A model_tps_avg model_mem_avg

# Calculate averages
while IFS=, read -r model prompt tokens time tps memory; do
  [[ "$model" == "Model" ]] && continue  # Skip header

  model_tps_sum["$model"]=$(echo "${model_tps_sum["$model"]} + $tps" | bc -l)
  model_mem_sum["$model"]=$(echo "${model_mem_sum["$model"]} + $memory" | bc -l)
  model_count["$model"]=$((${model_count["$model"]} + 1))
done < "$RESULTS_CSV"

# Find best performer
best_tps=0
best_model=""

for model in "${!model_count[@]}"; do
  model_tps_avg["$model"]=$(echo "${model_tps_sum["$model"]} / ${model_count["$model"]}" | bc -l)
  model_mem_avg["$model"]=$(echo "${model_mem_sum["$model"]} / ${model_count["$model"]}" | bc -l)

  if (( $(echo "${model_tps_avg["$model"]} > $best_tps" | bc -l) )); then
    best_tps=${model_tps_avg["$model"]}
    best_model="$model"
  fi

  # Add to HTML report
  if [ "$model" == "$best_model" ]; then
    echo "<tr class=\"best-result\"><td>$model</td><td>$(printf "%.2f" ${model_tps_avg["$model"]})</td><td>$(printf "%.2f" ${model_mem_avg["$model"]})</td></tr>" >> "$HTML_REPORT"
  else
    echo "<tr><td>$model</td><td>$(printf "%.2f" ${model_tps_avg["$model"]})</td><td>$(printf "%.2f" ${model_mem_avg["$model"]})</td></tr>" >> "$HTML_REPORT"
  fi
done

# Create detail section
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
  # Highlight best model
  if [ "$model" == "$best_model" ]; then
    echo "<tr class=\"best-result\"><td>$model</td><td>$prompt</td><td>$tokens</td><td>$(printf "%.2f" $time)</td><td>$(printf "%.2f" $tps)</td><td>$memory</td></tr>" >> "$HTML_REPORT"
  else
    echo "<tr><td>$model</td><td>$prompt</td><td>$tokens</td><td>$(printf "%.2f" $time)</td><td>$(printf "%.2f" $tps)</td><td>$memory</td></tr>" >> "$HTML_REPORT"
  fi
done

# Finish HTML
cat >> "$HTML_REPORT" << EOF
    </table>

    <h2>Conclusions</h2>
    <p>Based on the benchmark results, <strong>${best_model}</strong> offers the best performance for this specific hardware configuration with an average speed of <strong>$(printf "%.2f" ${model_tps_avg["$best_model"]}) tokens/second</strong>.</p>

    <p><em>Generated on $(date) by Ollama Benchmark Script</em></p>
</body>
</html>
EOF

# Export summary data for display script
export best_model
export best_tps
export -A model_tps_avg model_mem_avg

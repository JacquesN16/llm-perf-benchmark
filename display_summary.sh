#!/bin/bash
#
# DISPLAY SUMMARY
# Shows benchmark results summary in terminal

echo "Results saved to:"
echo "- CSV: $RESULTS_CSV"
echo "- HTML Report: $HTML_REPORT"
echo "- Raw outputs in $RESULTS_DIR"
echo ""

echo "Summary of results:"
echo "---------------------------------"
printf "%-20s %-15s %-15s\n" "Model" "Avg Tokens/sec" "Avg Memory (MB)"
echo "---------------------------------"

for model in "${!model_tps_avg[@]}"; do
  if [ "$model" == "$best_model" ]; then
    printf "%-20s \033[1;32m%-15.2f %-15.2f\033[0m\n" "$model" "${model_tps_avg["$model"]}" "${model_mem_avg["$model"]}"
  else
    printf "%-20s %-15.2f %-15.2f\n" "$model" "${model_tps_avg["$model"]}" "${model_mem_avg["$model"]}"
  fi
done

echo "---------------------------------"
echo "Fastest model: $best_model ($(printf "%.2f" ${model_tps_avg["$best_model"]}) tokens/sec)"
echo ""
echo "Open the HTML report for detailed results and visualization."

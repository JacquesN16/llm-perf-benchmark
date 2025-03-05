#!/bin/bash
#
# DOWNLOAD MODELS
# Downloads all models specified in config

for i in "${!MODELS[@]}"; do
  model="${MODELS[$i]}"
  echo "Pulling $model..."
  ollama pull "$model"
  show_progress "$((i+1))" "${#MODELS[@]}" "Models downloaded"
done
echo ""

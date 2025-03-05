# LLM Benchmarking Tool

A modular tool for benchmarking local LLM performance with Ollama.

## Components

- `main.sh` - Main orchestration script
- `config.sh` - Configuration settings
- `helpers.sh` - Utility functions
- `download_models.sh` - Model download
- `run_benchmarks.sh` - Execute benchmarks
- `generate_reports.sh` - Create reports
- `display_summary.sh` - Show results
- `install.sh` - Setup environment

## Installation

1. Clone or extract all files to a directory
2. Run installation script:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

## Usage

Run the main script:
```bash
./main.sh
```

## Configuration

Edit `config.sh` to customize:
- Models to benchmark
- Test prompts
- Number of tokens to generate

## Output

The tool generates:
- CSV data file
- HTML report with visualization
- Terminal summary
- Raw model outputs

## Requirements

- Linux system
- Ollama installed
- `bc` package for calculations
- Sudo access (for cache clearing)

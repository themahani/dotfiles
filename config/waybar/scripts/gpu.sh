#!/bin/bash

# Get GPU utilization
gpu_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)

# Get VRAM usage
vram_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
vram_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
vram_perc=$((vram_used * 100 / vram_total))

# Output JSON for Waybar
echo "{\"text\": \"$gpu_util\", \"tooltip\": \"VRAM: $vram_perc% ($vram_used MiB / $vram_total MiB)\"}"

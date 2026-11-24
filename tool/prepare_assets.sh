#!/usr/bin/env bash
set -euo pipefail
mkdir -p assets/fonts assets/images
font_url='https://raw.githubusercontent.com/google/fonts/main/ofl/manrope/Manrope%5Bwght%5D.ttf'
curl --fail --location --silent --show-error "$font_url" --output /tmp/moogs-Manrope.ttf
for weight in ExtraLight Light Regular Medium Bold; do
  cp /tmp/moogs-Manrope.ttf "assets/fonts/Manrope-$weight.ttf"
done

#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
output_file="$script_dir/MANUSCRIPT.md"

shopt -s nullglob
chapter_files=("$script_dir"/[0-9][0-9][0-9].md)

if ((${#chapter_files[@]} == 0)); then
  echo "No chapter files matching [0-9][0-9][0-9].md were found." >&2
  exit 1
fi

temp_file=$(mktemp)
cleanup() {
  rm -f "$temp_file"
}
trap cleanup EXIT

printf '# Silent Emergence\n\nA Novel by Joshua Szepietowski\n' > "$temp_file"

for chapter_file in "${chapter_files[@]}"; do
  chapter_heading=$(awk '
    NR == 1 {
      if ($0 !~ /^# /) {
        exit 1
      }

      sub(/^# /, "")
      print
      exit
    }
  ' "$chapter_file") || {
    echo "Expected the first line of $chapter_file to be a top-level heading." >&2
    exit 1
  }

  printf '\n## %s\n\n' "$chapter_heading" >> "$temp_file"

  awk -v heading="# $chapter_heading" '
    NR == 1 {
      next
    }

    body_started == 0 {
      if ($0 == heading) {
        next
      }

      if ($0 ~ /^[[:space:]]*$/) {
        next
      }

      body_started = 1
    }

    {
      print
    }
  ' "$chapter_file" >> "$temp_file"

  printf '\n' >> "$temp_file"
done

mv "$temp_file" "$output_file"
trap - EXIT

echo "Wrote $output_file"
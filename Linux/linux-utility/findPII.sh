#!/bin/bash
# Optimized PII Scanner for Cyber Defense Exercises
# Scans a given directory for SSNs and phone numbers (emails removed for speed/privacy).

# Default values
directory="/"
output="pii_report.txt"

# Parse command-line options
while getopts "d:o:" opt; do
  case $opt in
    d) directory="$OPTARG" ;;
    o) output="$OPTARG" ;;
    *) echo "Usage: $0 -d [directory_to_scan] -o [output_file]"; exit 1 ;;
  esac
done

echo "Scanning directory: $directory"
echo "Results will be saved to: $output"

# Only SSN and phone number patterns
pattern='([0-9]{3}-[0-9]{2}-[0-9]{4})|(\(?[0-9]{3}\)?[-. ][0-9]{3}[-. ][0-9]{4})'

# Clear output file
: > "$output"

# Build the find command with exclusions if scanning root
if [ "$directory" = "/" ]; then
  excluded_dirs=(
    /bin /boot /dev /lib /lib64 /proc /run /sbin /snap /sys /tmp /usr /var/cache /var/lib /var/log
  )

  # Create exclusion options for find
  exclude_expr=""
  for dir in "${excluded_dirs[@]}"; do
    exclude_expr+=" -path $dir -prune -o"
  done

  # Run the find command, excluding non-user dirs
  eval "find \"$directory\" $exclude_expr -type f -print0" 2>/dev/null | \
  xargs -0 -n 1 -P "$(nproc)" -I {} bash -c '
    file="{}"
    if grep -Iq . "$file"; then
      matches=$(grep -E "$0" "$file" 2>/dev/null)
      if [[ -n "$matches" ]]; then
        {
          echo "File: $file"
          echo "$matches" | sed "s/^/  /"
          echo ""
        } >> "'"$output"'"
      fi
    fi
  ' "$pattern"

else
  # For user-specified dirs, scan all files
  find "$directory" -type f -print0 2>/dev/null | \
  xargs -0 -n 1 -P "$(nproc)" -I {} bash -c '
    file="{}"
    if grep -Iq . "$file"; then
      matches=$(grep -E "$0" "$file" 2>/dev/null)
      if [[ -n "$matches" ]]; then
        {
          echo "File: $file"
          echo "$matches" | sed "s/^/  /"
          echo ""
        } >> "'"$output"'"
      fi
    fi
  ' "$pattern"
fi

echo "PII scan complete. Check '$output' for results."

#!/bin/bash
# PII Scanner Bash Script for Cyber Defense Exercises
#
# This script recursively scans a specified directory for common PII patterns
# (emails, SSNs, and phone numbers) and writes any findings to an output file.
#
# Usage: ./pii_scanner.sh -d [directory_to_scan] -o [output_file]
# Example: ./pii_scanner.sh -d / -o pii_report.txt


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

# Define a combined regex pattern for PII.
# - Emails: Matches most email formats.
# - SSNs: Matches U.S. Social Security numbers (e.g., 123-45-6789).
# - Phone numbers: Matches (123) 456-7890, 123-456-7890, or 123.456.7890.
pattern='([[:alnum:]_.+-]+@[[:alnum:]-]+\.[[:alnum:].-]+)|([0-9]{3}-[0-9]{2}-[0-9]{4})|(\(?[0-9]{3}\)?[-. ][0-9]{3}[-. ][0-9]{4})'

# Create or clear the output file
: > "$output"

# If scanning the entire filesystem, exclude directories that are unlikely to hold user PII.
if [ "$directory" = "/" ]; then
    find "$directory" \( \
        -path "/bin" -o \
        -path "/boot" -o \
        -path "/snap" -o \
        -path "/sbin" -o \
        -path "/lib" -o \
        -path "/lib64" -o \
        -path "/proc" -o \
        -path "/sys" -o \
        -path "/usr" -o \
        -path "/dev" \
    \) -prune -o -type f -print0 2>/dev/null | while IFS= read -r -d '' file; do
        matches=$(grep -I -E "$pattern" "$file" 2>/dev/null)
        if [[ -n "$matches" ]]; then
            {
                echo "File: $file"
                echo "$matches" | sed 's/^/  /'
                echo ""
            } >> "$output"
        fi
    done
else
    # For non-root directories, scan all files.
    find "$directory" -type f -print0 2>/dev/null | while IFS= read -r -d '' file; do
        matches=$(grep -I -E "$pattern" "$file" 2>/dev/null)
        if [[ -n "$matches" ]]; then
            {
                echo "File: $file"
                echo "$matches" | sed 's/^/  /'
                echo ""
            } >> "$output"
        fi
    done
fi

echo "PII scan complete. Check '$output' for results."

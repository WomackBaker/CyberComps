#!/usr/bin/env bash
#
# check_profiles.sh
#
# A script to enumerate profile/rc files system-wide and per-user,
# searching for suspicious lines that might indicate persistence.
#

# Adjust these patterns as needed. The \b ensures we match on word boundaries,
# and the parentheses group them. The explicit '(\s|^|;|&&)' before the command
# helps detect actual usage rather than mere mentions in a path or comment.
SUSPICIOUS_PATTERNS='\b(nc|wget|curl|bash|sh|python|perl|ruby|chmod|chown|chattr|systemctl|service|nohup|rm\s*-rf|scp|sftp|ftp|cron|echo\s+[^>]*>)\b'

# System-wide profile-like files/directories to check
SYSTEM_FILES=(
  "/etc/profile"
  "/etc/bashrc"
  "/etc/zshrc"
  "/etc/environment"
)

SYSTEM_DIRS=(
  "/etc/profile.d"
)

echo "===== Checking system-wide profile files ====="
for file in "${SYSTEM_FILES[@]}"; do
  if [[ -f "$file" ]]; then
    echo -e "\n[+] Checking $file"
    # Only grep lines that do NOT start with '#' (after optional whitespace)
    grep -Eni "^[[:space:]]*[^#].*${SUSPICIOUS_PATTERNS}" "$file" 2>/dev/null
  fi
done

echo -e "\n===== Checking system-wide profile.d directory ====="
for dir in "${SYSTEM_DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    for f in "$dir"/*; do
      # Ensure it's a regular file (not a directory, symlink, etc.)
      if [[ -f "$f" ]]; then
        echo -e "\n[+] Checking $f"
        grep -Eni "^[[:space:]]*[^#].*${SUSPICIOUS_PATTERNS}" "$f" 2>/dev/null
      fi
    done
  fi
done

echo -e "\n===== Checking user-specific profile files ====="

# Read /etc/passwd to find real user shells and home directories.
# We only check users with home directories & known shells (bash, zsh, etc.).
while IFS=: read -r user _ uid _ _ home shell; do
  # Ignore system users (uid < 1000 or home doesn't exist) by default. Adjust as needed.
  if [[ "$uid" -ge 1000 && -d "$home" && "$shell" =~ (bash|zsh|ksh|sh) ]]; then
    
    # Common user shell initialization files
    USER_FILES=(
      ".bashrc"
      ".bash_profile"
      ".profile"
      ".zshrc"
      ".zlogin"
      ".kshrc"
      ".login"
    )
    
    for uf in "${USER_FILES[@]}"; do
      user_file="$home/$uf"
      if [[ -f "$user_file" ]]; then
        echo -e "\n[+] Checking $user_file for user $user"
        grep -Eni "^[[:space:]]*[^#].*${SUSPICIOUS_PATTERNS}" "$user_file" 2>/dev/null
      fi
    done
  fi
done < /etc/passwd

echo -e "\n===== Profile Check Complete ====="

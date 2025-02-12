#!/usr/bin/env bash
#
# change-passwords-generate-unique.sh
#
# For each valid login user on a Unix-like system, generate a different random password and set it.
# Excludes users listed in an exclude file.
# Prints a summary of user:password at the end.

# -----------------------------
# 1. Configuration
# -----------------------------

EXCLUDE_FILE="$HOME/Linux/exclude.txt"

noLoginShells=(
  "/bin/false"
  "/usr/sbin/nologin"
  "/usr/bin/nologin"
  "/sbin/nologin"
)

# -----------------------------
# 2. OS Detection
# -----------------------------
OS="unknown"

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS="$ID"
elif [[ "$(uname -s)" == "FreeBSD" ]]; then
  OS="freebsd"
fi

# -----------------------------
# 3. Read Excluded Users
# -----------------------------

declare -A excludedUsersMap

if [[ -f "$EXCLUDE_FILE" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    excludedUsersMap["$line"]=1
  done < "$EXCLUDE_FILE"
else
  printf "Exclude file not found: %s\nNo users will be excluded unless you update it.\n" "$EXCLUDE_FILE" >&2
fi

# -----------------------------
# 4. Functions
# -----------------------------

generate_password() {
  local pass
  pass=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c16) || return 1
  [[ -n "$pass" ]] && printf "%s" "$pass" || return 1
}

set_password() {
  local user="$1"
  local pass="$2"

  case "$OS" in
    freebsd)
      printf "%s\n" "$pass" | pw usermod "$user" -h 0
      ;;
    *)
      printf "%s:%s\n" "$user" "$pass" | chpasswd
      ;;
  esac
}

# -----------------------------
# 5. Determine user list source
# -----------------------------
userListCmd="cat /etc/passwd"
if command -v getent &>/dev/null; then
  userListCmd="getent passwd"
fi

# -----------------------------
# 6. Process Each User
# -----------------------------
declare -A userPasswords

while IFS=: read -r username _ uid _ _ _ shell; do
  [[ ${excludedUsersMap["$username"]} ]] && continue

  for nlShell in "${noLoginShells[@]}"; do
    [[ "$shell" == "$nlShell" ]] && continue 2
  done

  (( uid < 1000 )) && continue

  newPass=$(generate_password) || { printf "Failed to generate password for %s\n" "$username" >&2; continue; }

  if set_password "$username" "$newPass"; then
    userPasswords["$username"]="$newPass"
    printf "Password changed for user: %s\n" "$username"
  else
    printf "Failed to change password for user: %s\n" "$username" >&2
  fi
done < <($userListCmd)

# -----------------------------
# 7. Print Summary
# -----------------------------
printf "\n==============================\nGenerated Passwords Summary\n==============================\n"
for user in "${!userPasswords[@]}"; do
  printf "%s:%s\n" "$user" "${userPasswords[$user]}"
done
printf "==============================\nScript completed.\n"

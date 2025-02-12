#!/usr/bin/env bash
#
# change-passwords-generate-unique.sh
#
# For each valid login user on a Unix-like system (Ubuntu, Debian, CentOS, Rocky,
# Fedora, FreeBSD), generate a different random password and set it.
# Excludes users listed in an exclude file (e.g., exclude.txt).
# Prints a summary of user:password at the end.

# -----------------------------
# 1. Configuration
# -----------------------------

# Path to the exclude file
EXCLUDE_FILE="$HOME/Linux/exclude.txt"  # changed $HOME to $HOME for proper expansion

# Typical "no-login" shells on many systems:
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

if [ -f /etc/os-release ]; then
  # Source the file so variables like $ID are set (e.g., "ubuntu", "debian", "centos", "rocky", "fedora")
  . /etc/os-release
  OS="$ID"
elif [ "$(uname -s)" = "FreeBSD" ]; then
  OS="freebsd"
fi

# -----------------------------
# 3. Read Excluded Users
# -----------------------------

# We will read an external file containing excluded user names (one per line).
declare -a excludedUsers=()

if [[ -f "$EXCLUDE_FILE" ]]; then
  # Read each line of EXCLUDE_FILE into the excludedUsers array
  while IFS= read -r line; do
    # Skip empty lines or lines starting with #
    [[ -z "$line" || "$line" =$HOME ^# ]] && continue
    excludedUsers+=("$line")
  done < "$EXCLUDE_FILE"
else
  echo "Exclude file not found: $EXCLUDE_FILE"
  echo "No users will be excluded unless you update $EXCLUDE_FILE."
fi

# -----------------------------
# 4. Functions
# -----------------------------

# 4.1 Generate a random password using only built-in tools
generate_password() {
  # Adjust character set or length as needed
  < /dev/urandom tr -dc 'A-Za-z0-9' | head -c16
}

# 4.2 Set the password depending on OS
set_password() {
  local user="$1"
  local pass="$2"

  case "$OS" in
    freebsd)
      # On FreeBSD: use 'pw usermod ... -h 0' to read password from stdin
      echo "$pass" | pw usermod "$user" -h 0
      ;;
    *)
      # On Linux (Ubuntu, Debian, CentOS, Rocky, Fedora): use chpasswd
      echo "$user:$pass" | chpasswd
      ;;
  esac
}

# -----------------------------
# 5. Determine user list source
# -----------------------------
# We'll prefer 'getent passwd' if available, otherwise fallback to '/etc/passwd'
userListCmd="cat /etc/passwd"
if command -v getent &>/dev/null; then
  userListCmd="getent passwd"
fi

# -----------------------------
# 6. Process Each User
# -----------------------------
declare -A userPasswords  # Associative array to store user->generated_password

$userListCmd | while IFS=: read -r username _ uid gid fullname home shell; do

  # 6.1 Check if user is in excluded list
  if printf '%s\n' "${excludedUsers[@]}" | grep -qx "$username"; then
    # Found in excluded list; skip this user
    continue
  fi

  # 6.2 Check if this shell indicates "no login"
  for nlShell in "${noLoginShells[@]}"; do
    if [[ "$shell" == "$nlShell" ]]; then
      # It's a no-login shell; skip
      continue 2
    fi
  done

  # 6.3 Skip system/daemon accounts with UID < 1000
  if [ "$uid" -lt 1000 ]; then
    continue
  fi

  # (Optional) If you also want to skip users with very large UIDs (like nobody at 65534),
  # you can do something like:
  # if [ "$uid" -gt 60000 ]; then
  #   continue
  # fi

  # 6.4 Generate a random password, then set it
  newPass="$(generate_password)"
  if set_password "$username" "$newPass"; then
    userPasswords["$username"]="$newPass"
    echo "Password changed for user: $username"
  else
    echo "Failed to change password for user: $username"
  fi
done

# -----------------------------
# 7. Print Summary
# -----------------------------
echo
echo "=============================="
echo "Generated Passwords Summary"
echo "=============================="
for user in "${!userPasswords[@]}"; do
  echo "${user}:${userPasswords[$user]}"
done
echo "=============================="
echo "Script completed."
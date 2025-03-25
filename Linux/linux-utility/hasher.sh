#!/bin/bash

# Where we store the previous known state
OUTFILE="/root/Linux/linux-utility/hashes.txt"

# Where we log alerts
LOGFILE="/root/Linux/script_log.txt"

# Check for root privileges (so we can read /etc/shadow)
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root or via sudo."
  exit 1
fi

while true
do
  # -----------------------------------------------------------------------------
  # 1) Read current state of /etc/passwd and /etc/shadow into associative arrays
  #    Key: username
  #    Value: the full line from /etc/passwd or /etc/shadow
  # -----------------------------------------------------------------------------
  declare -A current_passwd
  declare -A current_shadow

  # Load /etc/passwd
  while IFS= read -r line; do
    # username is everything before the first :
    user="$(echo "$line" | cut -d: -f1)"
    current_passwd["$user"]="$line"
  done < /etc/passwd

  # Load /etc/shadow
  while IFS= read -r line; do
    user="$(echo "$line" | cut -d: -f1)"
    current_shadow["$user"]="$line"
  done < /etc/shadow

  # -----------------------------------------------------------------------------
  # 2) Load old state (if it exists) from $OUTFILE into two arrays
  #    Format in $OUTFILE:
  #       # passwd
  #       user1:...
  #       user2:...
  #       ...
  #       # shadow
  #       user1:...
  #       user2:...
  #       ...
  # -----------------------------------------------------------------------------
  declare -A old_passwd
  declare -A old_shadow

  if [[ -f "$OUTFILE" ]]; then
    current_section=""
    while IFS= read -r line; do
      # Skip blank lines
      if [[ -z "$line" ]]; then
        continue
      fi
      # If we hit a marker line
      if [[ "$line" == "# passwd" ]]; then
        current_section="passwd"
        continue
      elif [[ "$line" == "# shadow" ]]; then
        current_section="shadow"
        continue
      fi

      # Otherwise, line is either a passwd or shadow entry
      if [[ "$current_section" == "passwd" ]]; then
        user="$(echo "$line" | cut -d: -f1)"
        old_passwd["$user"]="$line"
      elif [[ "$current_section" == "shadow" ]]; then
        user="$(echo "$line" | cut -d: -f1)"
        old_shadow["$user"]="$line"
      fi
    done < "$OUTFILE"
  fi

  # -----------------------------------------------------------------------------
  # 3) Compare old state vs. new state to detect changes
  # -----------------------------------------------------------------------------

  #
  # 3a) Check for new or changed /etc/passwd entries
  #
  for user in "${!current_passwd[@]}"; do
    if [[ -z "${old_passwd[$user]}" ]]; then
      # User wasn't in old data at all => new user
      echo "ALERT: New user added: $user"
      echo "$(date): ALERT: New user added: $user" >> "$LOGFILE"
    else
      # User existed previously; check if the /etc/passwd line changed
      if [[ "${current_passwd[$user]}" != "${old_passwd[$user]}" ]]; then
        echo "ALERT: User $user's /etc/passwd entry changed (shell/home/UID/GID etc.)"
        echo "$(date): ALERT: User $user's /etc/passwd entry changed" >> "$LOGFILE"
      fi
    fi
  done

  #
  # 3b) Check for removed /etc/passwd entries
  #
  for user in "${!old_passwd[@]}"; do
    if [[ -z "${current_passwd[$user]}" ]]; then
      # User was in old data but not in current => user removed
      echo "ALERT: User removed: $user"
      echo "$(date): ALERT: User removed: $user" >> "$LOGFILE"
    fi
  done

  #
  # 3c) Check for new or changed /etc/shadow entries
  #
  for user in "${!current_shadow[@]}"; do
    if [[ -z "${old_shadow[$user]}" ]]; then
      # Possibly a new user with a shadow line
      echo "ALERT: New /etc/shadow entry for user: $user"
      echo "$(date): ALERT: New /etc/shadow entry for user: $user" >> "$LOGFILE"
    else
      # If the line changed => password, lock status, expiry date, etc. changed
      if [[ "${current_shadow[$user]}" != "${old_shadow[$user]}" ]]; then
        echo "ALERT: User $user's /etc/shadow entry changed (password or expiry changed)"
        echo "$(date): ALERT: User $user's shadow entry changed" >> "$LOGFILE"
      fi
    fi
  done

  #
  # 3d) Check for removed /etc/shadow entries (rare, but possible)
  #
  for user in "${!old_shadow[@]}"; do
    if [[ -z "${current_shadow[$user]}" ]]; then
      echo "ALERT: /etc/shadow entry for user $user was removed"
      echo "$(date): ALERT: /etc/shadow entry for user $user was removed" >> "$LOGFILE"
    fi
  done

  # -----------------------------------------------------------------------------
  # 4) Update $OUTFILE with the new state (overwrite old data)
  # -----------------------------------------------------------------------------
  {
    echo "# passwd"
    for user in "${!current_passwd[@]}"; do
      echo "${current_passwd[$user]}"
    done
    echo ""
    echo "# shadow"
    for user in "${!current_shadow[@]}"; do
      echo "${current_shadow[$user]}"
    done
  } > "$OUTFILE"

  # -----------------------------------------------------------------------------
  # 5) Sleep 10 seconds before checking again
  # -----------------------------------------------------------------------------
  sleep 10
done

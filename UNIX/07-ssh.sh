#!/usr/bin/env bash
# Secure SSH configuration script for Linux and Unix-like systems.

# Determine sed in-place syntax.
if [ "$(uname -s)" = "Linux" ]; then
  SED_INPLACE="sed -i"
else
  # For BSD-style sed (including macOS), an empty extension is required.
  SED_INPLACE="sed -i ''"
fi

# Check if sshd service is running.
if service sshd status > /dev/null 2>&1; then
	# Uncomment the next line if you wish to allow root login via SSH.
	# $SED_INPLACE '1s;^;PermitRootLogin yes\n;' /etc/ssh/sshd_config

	$SED_INPLACE '1s;^;PubkeyAuthentication no\n;' /etc/ssh/sshd_config

	# Disable UsePAM on non-RedHat systems (if /etc/os-release exists)
	if [ -f /etc/os-release ] && ! grep -q "REDHAT_" /etc/os-release; then
		$SED_INPLACE '1s;^;UsePAM no\n;' /etc/ssh/sshd_config
	fi

	$SED_INPLACE '1s;^;UseDNS no\n;' /etc/ssh/sshd_config
	$SED_INPLACE '1s;^;PermitEmptyPasswords no\n;' /etc/ssh/sshd_config
	$SED_INPLACE '1s;^;AddressFamily inet\n;' /etc/ssh/sshd_config

	# Test sshd configuration; if good, restart sshd using the available method.
	if sshd -t; then
	  if command -v systemctl >/dev/null 2>&1; then
	    systemctl restart sshd
	  else
	    service sshd restart
	  fi
	else
	  echo "Error: sshd configuration test failed."
	fi
fi

#!/bin/bash

sudo tail -f "/var/log/auth.log" | grep snoopy | grep -vE "grep -qE|grep -qx|grep -qw|pkillBash.sh|ensureCorrectUsers.sh|grep -E (nc|netcat|bash|sh|zsh|mkfifo|python|perl|ruby|wget|curl)"
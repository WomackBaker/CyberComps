#!/bin/bash

~/Linux/pspy64 | grep -vE "grep -qE|grep -qx|grep -qw|pkillBash.sh|ensureCorrectUsers.sh|grep -E (nc|netcat|bash|sh|zsh|mkfifo|python|perl|ruby|wget|curl)"
#!/bin/bash

echo -n "Enter IP Address: "
read ip
sudo ufw deny from $ip

#!/usr/bin/env bash

# Get disk usage percentage
usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

# Get available space in human readable format
available=$(df -h / | tail -1 | awk '{print $4}')

echo "DISK ${usage}% (${available})" 
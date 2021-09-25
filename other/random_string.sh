#!/bin/bash
# 
# Generate random string
#

LEN=42 # Length of the random link

date +%s | sha256sum | base64 | head -c $LEN ; echo

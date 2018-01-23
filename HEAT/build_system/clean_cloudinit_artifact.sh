#!/bin/bash

# Remove cloud-init artifact
# you can't remove cloud-init artifact using setup script run by cloud-init
# Run this script before snapshot!!!

echo 'Removing cloud-init artifact'
rm -rf /var/lib/cloud/*
rm /var/log/cloud-init.log
rm /var/log/cloud-init-output.log

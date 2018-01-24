#!/bin/bash
# Clean instance and get it ready for snapshot.

#________________________________
# Get Distribution
if [[ -r /etc/os-release ]]; then
    . /etc/os-release
fi

#________________________________
# Remove cloud-init artifact
# you can't remove cloud-init artifact using setup script run by cloud-init
# Run this script before snapshot!!!

echo 'Removing cloud-init artifact'
rm -rf /var/lib/cloud/*
rm /var/log/cloud-init.log
rm /var/log/cloud-init-output.log

#________________________________
# Delete cloud-init user

echo "Remove default user"
if [[ $ID = "ubuntu" ]]; then
  userdel -r -f ubuntu
else
  userdel -r -f centos
fi

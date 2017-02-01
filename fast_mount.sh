#!/bin/bash

USER=$1
DEVICE=$2
MOUNTPOINT=$3

mkfs.ext4 $2
mount $2  $3
chown $1:$1 $3

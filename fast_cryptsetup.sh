#!/bin/bash

LOGFILE="/tmp/fast_cryptsetup.log"

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo $ID > $LOGFILE
    if [ "$ID" = "ubuntu" ]; then
        echo "Distribution: Ubuntu. Using apt" > $LOGFILE
        apt-get install -y cryptsetup &>> $LOGFILE
    else
        echo "Distribution: CentOS. Using yum" > $LOGFILE
        yum install -y cryptsetup-luks pv &>> $LOGFILE
    fi
else
    echo "Not running a distribution with /etc/os-release available" > $LOGFILE
fi


###
cryptsetup -y -v luksFormat /dev/vdb

cryptsetup luksOpen /dev/vdb galaxy_data

cryptsetup -v status galaxy_data

cryptsetup luksDump /dev/vdb

dd if=/dev/zero of=/dev/mapper/galaxy_data

pv -tpreb /dev/zero | dd of=/dev/mapper/galaxy_data bs=128M

mkfs.ext4 /dev/mapper/galaxy_data

mount /dev/mapper/galaxy_data /export

df -H

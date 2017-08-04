#!/bin/bash

# LUKS central management tool
# This script requires dmsetup and cryptsetup.
# Needs to be launched as superuser.
#
# Author: Marco Tangaro
# mail: ma.tangaro@gmail.com
# 
# LICENCE: Apache 2.0 software licence

VERSION='0.0.1 (alpha)'
DEBUG=false

################################################################################
# VARIABLES

# date
now=$(date +"-%b-%d-%y-%H%M%S")

# colors for errors and warnings        
red=$(tput setab 0; tput setaf 1)
yellow=$(tput setab 0; tput setaf 3)
none=$(tput sgr0)

# colors for messages
green="\033[32m"
blue="\033[34m"
normal="\033[0m"

# ok and fail variables
_ok="[$green OK $none]"
_stop="[ STOP ]"
_fail=" [$red FAIL $none]"



################################################################################
# LUKS FUNCTIONS

cryptdev_conf_file='/etc/luks-cryptdev.conf'

#____________________________________
# Script needs superuser

function __su_check(){
  if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo -e "[Error] Not running as root: ${_fail}"
    exit
 fi
}

#____________________________________
# Display dmsetup info

function __dmsetup_info(){
  dmsetup info /dev/mapper/${CRYPTDEV}
}

#____________________________________
# check encrypted storage mounted
function __cryptdev_status(){
  __dmsetup_info &>/dev/null
  if [ $? -eq 0 ]; then
    echo -e "\nEncrypted volume: ${_ok}"
  else
    echo -e "\nEncrypted volume: ${_fail}"
  fi
}

#____________________________________
# luksOpen device

function __luksopen_cryptdev(){
  cryptsetup luksOpen /dev/disk/by-uuid/${UUID} ${CRYPTDEV}
  dmsetup info /dev/mapper/${CRYPTDEV}
  mount /dev/mapper/${CRYPTDEV} $MOUNTPOINT
  code=$?
  if [ "$code" -ne 0 ]; then
    return 31 # return error code 0
  else 
    chown galaxy:galaxy $MOUNTPOINT
    return 0 # return success
  fi
}

#____________________________________
# Open encrypted device

function __cryptdev_open(){
  __luksopen_cryptdev
  code=$?
  if [ "$code" -eq "0" ]; then
    __cryptdev_status
  else
    echo -e "\nEncrypted volume mount: ${_fail}"
  fi
}

#____________________________________
# luksClose device 

function __luksclose_cryptdev(){
  umount $MOUNTPOINT
  cryptsetup close ${CRYPTDEV}
}

#____________________________________
# Close encrypted device

function __cryptdev_close(){
  __luksclose_cryptdev
  __dmsetup_info &>/dev/null
  if [ $? -eq 0 ]; then
    echo -e "\nEncrypted volume umount: ${_fail}"
  else
    echo -e "\nEncrypted volume umount: ${_ok}"
  fi
}

#____________________________________
# Show Galaxy intro

function __cryptdev_intro(){
  echo -e "==============================================================="
  echo -e "   Galaxy Central Management Tool (LUKS section)"
  echo -e ""
  echo -e "   Version : ${VERSION}"
  echo -e ""
  echo -e "   Cipher algorithm: ${CIPHER_ALGORITHM}"
  echo -e "   Hash: ${HASH_ALGORITHM}"
  echo -e "   Key size: ${KEYSIZE}"
  echo -e "   Device UUID: ${UUID}"
  echo -e "   Device mapper: ${MAPPER}"
  echo -e "   Mountpoint: ${MOUNTPOINT}"
  echo -e "   Filesystem: ${FILESYSTEM}"
  echo -e "" 
  echo -e "==============================================================="
}


#____________________________________
# Show Galaxy help

function __cryptdev_help(){
  echo -e "\nUsage: galaxyctl luks <option>"
  echo -e "\nEncrypted volume options:\n"
  echo -e "  - help [print-out cryptdevice options]\n"
  echo -e '  - open [luks open and mount volume]\n'
  echo -e '  - close [luks close and umount volume]\n'
  echo -e '  - status [check volume status]\n'
}

#____________________________________
# Cryptdevice options

__su_check

if [ "$1" == luks ]; then
  source $cryptdev_conf_file
  __cryptdev_intro
  if [ "$2" == 'open' ]; then __cryptdev_open; fi
  if [ "$2" == 'close' ]; then __cryptdev_close; fi
  if [ "$2" == 'status' ]; then __cryptdev_status; fi
  if [ "$2" == 'help' ]; then __cryptdev_help; fi
fi

#!/bin/bash

# Galaxy central management tool
# This script requires msetup and cryptsetup.
# Needs to be launched as superuser.
#
# Author: Marco Tangaro
# mail: ma.tangaro@gmail.com
# 
# LICENCE: Apache 2.0 software licence


################################################################################
# VARIABLES

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
# GALAXY FUNCTIONS

supervisord_conf_path=/etc
supervisord_conf_file=${supervisord_conf_path}/supervisord.conf

#____________________________________
# Load Galaxy environment

function __load_galaxy_env(){
  echo -ne "\nLoading Galaxy virtual environment: "
  cd /home/galaxy/galaxy
  . /home/galaxy/galaxy/.venv/bin/activate
  echo -ne "${_ok}\n"
}


#____________________________________
# Check if supervisord is running
# Following the Unix convention of expecting utilities to return zero for success and non-zero for failure, so boolean conditions are inverted.

function __check_supervisord(){
  if ps ax | grep -v grep | grep supervisord > /dev/null
  then
    echo -e "\nSupervisord service: ${_ok}"
    return 0
  else
    echo -e "\nSupervisord service: ${_fail}."
    return 1
  fi
}


#____________________________________
# Check if Galaxy instance is up

function __galaxy_curl(){
  curl -s --head  --request GET http://90.147.102.96/galaxy | grep "200 OK" > /dev/null
}

function __galaxy_url_status(){
  if __galaxy_curl; then 
    echo -e "\nGalaxy server on-line: ${_ok}"
  else
    echo -e "\nGalaxy server on-line: ${_fail}"
  fi
}



#____________________________________
# Check if Galaxy instance is up

function __galaxy_server_status(){
  supervisorctl status galaxy:
}


#____________________________________

function __galaxy_ps(){
  ps -aux | grep "[u]wsgi" # brackets needed to avoid grep showing itself
}


#____________________________________
# Check if Galaxy instance is up

function __galaxy_status(){
  __galaxy_url_status
  echo -e "\nSupervisorctl status:"; __galaxy_server_status
  echo -e "\nuWSGI status:"; __galaxy_ps
}


#____________________________________
# Define start function
function __start_galaxy(){
  __load_galaxy_env

  if __check_supervisord ; then
    echo -e "\nStarting Galaxy: "
    supervisorctl start galaxy:
    
  else
    echo -e "\nStarting supervisord, Galaxy will be automatically started."
    /usr/bin/supervisord -c $supervisord_conf_file
  fi
}


#____________________________________
# Define stop function

function __stop_galaxy(){
  __load_galaxy_env

  echo -e "\nStopping galaxy using supervisord:\n"
  supervisorctl stop galaxy:

  echo -e "\nuWSGI nodes check: "
  if [ "$(pidof uwsgi)" ]; then
    # processes found
    echo -ne "  Killing uwsgi residual nodes: "
    kill -9 $(pidof uwsgi)
    echo -ne "${_ok}\n"
  else
  # process not found
  echo -ne "  uWSGI graceful stop ${_ok}\n"
  fi
}


#____________________________________
# Define restart function

function __restart_galaxy(){
  echo -e "\nRestarting the Galaxy production environment"
  __stop_galaxy
  __start_galaxy
}


#____________________________________
function __galaxy_help(){
  echo -e "\nUsage: galaxyctl galaxy <option>"
  echo -e "\nGalaxy options:\n"
  echo -e '  - help [print-out Galaxy options]\n'
  echo -e '  - start [start the Galaxy server]\n'
  echo -e '  - stop [stop the Galaxy server]\n'
  echo -e '  - restart [restart the Galaxy server]\n'
  echo -e '  - status [check the status of the whole service]\n'
  echo -e '  - on-line [check if Galaxy is Up and Running]\n'
  echo -e '  - ps [check uWSGI processes with ps]\n'
  echo -e '  - load-env [load Galaxy virtual environment]\n'
}

#
# Galaxy options
#

if [ "$1" == "galaxy" ]; then
  if [ "$2" == "start" ]; then __start_galaxy; fi
  if [ "$2" == "stop" ]; then __stop_galaxy; fi
  if [ "$2" == "restart" ]; then __restart_galaxy; fi
  if [ "$2" == "status" ]; then __galaxy_status; fi
  if [ "$2" == "on-line" ]; then __galaxy_url_status; fi
  if [ "$2" == "ps" ]; then __galaxy_ps; fi
  if [ "$2" == "load-env" ]; then __load_galaxy_env; fi
  if [ "$2" == "help" ]; then __galaxy_help; fi
fi


################################################################################
# STORAGE FUNCTIONS


cryptdev_conf_file='/etc/luks-cryptdev.conf'

#____________________________________
# check encrypted storage mounted

function __dmsetup_info(){
  dmsetup info /dev/mapper/${CRYPTDEV}
}

function __cryptdev_status(){
  __dmsetup_info &>/dev/null
  if [ $? -eq 0 ]; then
    echo -e "\nEncrypted volume: ${_ok}"
  else
    echo -e "\nEncrypted volume: ${_fail}"
  fi
}

#____________________________________
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
function __luksclose_cryptdev(){
  umount $MOUNTPOINT
  cryptsetup close ${CRYPTDEV}
}

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
function __cryptdev_help(){
  echo -e "\nUsage: galaxyctl cryptdevice <option>"
  echo -e "\nEncrypted volume options:\n"
  echo -e "  - help [print-out cryptdevice options]\n"
  echo -e '  - open [luks open and mount volume]\n'
  echo -e '  - close [luks close and umount volume]\n'
  echo -e '  - status [check volume status]\n'
}
#
# Cryptdevice options
#

if [ "$1" == cryptdevice ]; then
  source $cryptdev_conf_file
  if [ "$2" == 'open' ]; then __cryptdev_open; fi
  if [ "$2" == 'close' ]; then __cryptdev_close; fi
  if [ "$2" == 'status' ]; then __cryptdev_status; fi
  if [ "$2" == 'help' ]; then __cryptdev_help; fi
fi


################################################################################
# PRODUCTION ENVIRONMENT FUNCTION

# Print out intro banner
IP='90.147.102.96'
BRAND='INDIGO-CNR testing instance'

function __intro(){
  echo -e "==============================================================="
  echo -e "   ELIXIR-IIB Galaxy Central Management Tool - Alpha Version\n"
  echo -e "   Instance IP address: $IP"
  echo -e "   Instane Brand: $BRAND"
  echo -e "\n   Type \"galaxyctl server help\" to print out options"
  echo -e "==============================================================="
}

function __help(){
  echo -e "\nUsage: galaxyctl server <option>"
  echo -e "\nOptions:\n"
  echo -e "  - help [print-out help]\n"
  echo -e "  - status [display server status]\n"
  echo -e "  - init [init services]\n"

  __cryptdev_help
  __galaxy_help
}

#____________________________________
function __init(){

  #---
  # Encrypted volume section
  __dmsetup_info &>/dev/null
  if [ $? -eq 0 ]; then
    echo -e "\nEncrypted volume: ${_ok}"
  else
    echo -e "\nMounting encrypted volume..."
    __luksopen_cryptdev
    __init
  fi

  #---
  # Onedata section

  #---
  # Galaxy section
  if __galaxy_curl; then
    echo -e "\nGalaxy server on-line: ${_ok}"
  else
    __start_galaxy
    __galaxy_url_status
  fi

  # TODO if galaxy is not up, check supervisor, if supervisor is running check uwsgi master state
}

#
# Production environment options
#

if [ "$1" == server ]; then
  __intro
  if [ "$2" == 'help' ]; then __help; fi
  source ${cryptdev_conf_file}
  if [ "$2" == 'init' ]; then __init; fi
  if [ "$2" == 'status' ]; then __cryptdev_status; __galaxy_url_status; fi
fi


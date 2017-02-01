#!/bin/bash
# Bash script for managing LUKS volumes in Linux:
# You can create a virtual encrypted Linux FS volume from a file block.
# Helps you mount and unmount LUKS partitions.
#
# Author: Marco Tangaro
# Mail: ma.tangaro@gmail.com 
#
# Please find the original script here: https://github.com/JohnTroony/LUKS-OPs/blob/master/luks-ops.sh
# All credits to John Troon.


################################################################################
# Variables
constant="luks_"
cryptdev=$(cat < /dev/urandom | tr -dc "[:lower:]"  | head -c 8)
logs=$(cat < /dev/urandom | tr -dc "[:lower:]"  | head -c 4)    
temp_name="$constant$logs"
now=$(date +"-%b-%d-%y-%H%M%S")

# colors for errors and warnings	
red=$(tput setab 0; tput setaf 1)
yellow=$(tput setab 0; tput setaf 3)
none=$(tput sgr0)

# colors for messages
green="\033[32m"
blue="\033[34m"
normal="\033[0m"


################################################################################
# FUNCTIONS


#____________________________________
# Lock/UnLock Section
# http://wiki.bash-hackers.org/howto/mutex
# "trap -l" for signal summary

LOCKDIR=/tmp/fast_cryptsetup #TODO /var/lock/fast_cryptsetup.lock
PIDFILE=${LOCKDIR}/fast_cryptsetup.pid

# exit codes and text for them - additional features nobody needs :-)
ENO_SUCCESS=0; ETXT[0]="ENO_SUCCESS"
ENO_GENERAL=1; ETXT[1]="ENO_GENERAL"
ENO_LOCKFAIL=2; ETXT[2]="ENO_LOCKFAIL"
ENO_RECVSIG=3; ETXT[3]="ENO_RECVSIG"


function lock(){

  # start un/locking attempt
  trap 'ECODE=$?; echo "[statsgen] Exit: ${ETXT[ECODE]}($ECODE)" >&2' 0
  echo -n "[statsgen] Locking: " >&2


    if mkdir "${LOCKDIR}" &>/dev/null; then
      # lock succeeded, I'm storing the PID 
      echo "$$" >"${PIDFILE}"
      echo "success, installed signal handlers"

    else

      # lock failed, check if the other PID is alive
      OTHERPID="$(cat "${PIDFILE}")"
      # if cat isn't able to read the file, another instance is probably
      # about to remove the lock -- exit, we're *still* locked
      #  Thanks to Grzegorz Wierzowiecki for pointing out this race condition on
      #  http://wiki.grzegorz.wierzowiecki.pl/code:mutex-in-bash
      if [ $? != 0 ]; then
        echo "lock failed, PID ${OTHERPID} is active" >&2
        exit ${ENO_LOCKFAIL}
      fi

      if ! kill -0 $OTHERPID &>/dev/null; then
        # lock is stale, remove it and restart
        echo "removing stale lock of nonexistant PID ${OTHERPID}" >&2
        rm -rf "${LOCKDIR}"
        echo "[statsgen] restarting myself" >&2
        exec "$0" "$@"
      else
        # lock is valid and OTHERPID is active - exit, we're locked!
        echo "Lock failed, PID ${OTHERPID} is active" >&2
        echo "Another fast_cryptsetup process is active" >&2
        echo "If you're sure fast_cryptsetup is not already running,"
        echo "you can remove $LOCKDIR and restart fast_cryptsetup" >&2
        exit ${ENO_LOCKFAIL}
      fi
    fi
}

#____________________________________
function unlock(){
  # lock succeeded, install signal handlers before storing the PID just in case 
  # storing the PID fails
  trap 'ECODE=$?;
        echo "[statsgen] Removing lock. Exit: ${ETXT[ECODE]}($ECODE)" >&2
        rm -rf "${LOCKDIR}"' 0

  # the following handler will exit the script upon receiving these signals
  # the trap on "0" (EXIT) from above will be triggered by this trap's "exit" command!
  trap 'echo "[statsgen] Killed by a signal." >&2
        exit ${ENO_RECVSIG}' 1 2 3 15
}


#___________________________________
function info {
  echo CIPHER  = "${CIPHER}"
  echo KEYSIZE = "${KEYSIZE}"
}

#____________________________________
# Install cryptsetup

function install_cryptsetup {

  if [[ -r /etc/os-release ]]; then
      . /etc/os-release
      echo $ID
      if [ "$ID" = "ubuntu" ]; then
          echo "Distribution: Ubuntu. Using apt"
          apt-get install -y cryptsetup
      else
          echo "Distribution: CentOS. Using yum"
          yum install -y cryptsetup-luks pv
      fi
  else
      echo "Not running a distribution with /etc/os-release available"
  fi

}

#____________________________________
# Check cryptsetup installation

function check_cryptsetup {

  echo "Check if the required applications are installed..."
  type -P dmsetup &>/dev/null || echo -e "$red dmestup is not installed. Installing... $noine" #TODO add install device_mapper
  type -P cryptsetup &>/dev/null || { echo -e "$red cryptsetup is not installed. Installing... $none"; install_cryptsetup  >> "$LOGFILE" 2>&1; echo -e "$green cryptsetup installed! $none"; }

}

#____________________________________
# Check volume 

function check_volume {
  DEVICE=$(df -P $MOUNTPOINT | tail -1 | cut -d' ' -f 1)
  echo "Device name: $DEVICE"
}


#____________________________________
#FIXME cryptsetup (temporary version)

function encrypt {

  # Check which virtual volume is mounted to /export
  check_volume >> "$LOGFILE" 2>&1

  #Create the LUKS virtual volume

  #cryptsetup -y -v luksFormat $DEVICE

  #cryptsetup luksOpen /dev/vdb galaxy_data

  #cryptsetup -v status galaxy_data

  #cryptsetup luksDump /dev/vdb

  #dd if=/dev/zero of=/dev/mapper/galaxy_data

  #pv -tpreb /dev/zero | dd of=/dev/mapper/galaxy_data bs=128M

  #mkfs.ext4 /dev/mapper/galaxy_data

  #mount /dev/mapper/galaxy_data /export

  #df -H
}



################################################################################
# Main script

#LOGFILE="/tmp/luks$now.log"
LOGFILE="/tmp/fast_cryptsetup.log"


# Default values
CIPHER="aes-xts-plain64"
KEYSIZE="256"
DEVICE="/dev/vdb"
ADDRESS="galaxy_data"
MOUNTPOINT="/export"
FILESYSTEM="ext4"

# If running script with no arguments then loads defaults values.
if [ $# -lt 1 ]; then
  echo "No inputs. Using defaults values:" >> "$LOGFILE" 2>&1
  info >> "$LOGFILE" 2>&1
fi


# Parse CLI options

while [ $# -gt 0 ]
do

  case $1 in
    -c|--cipher) CIPHER="$2"; shift;;
    
    -k|--keysize) KEYSIZE="$2"; shift;;

    -d|--device) DEVICE="$2"; shift ;;

    -a|--address) ADDRESS="$2"; shift ;;

    -m|--mountpoint) MOUNTPOINT="$2"; shift ;;

    -p|--passphrase) PASSPHRASE="$2"; shift ;;

    -f|--filesystem) FILESYSTEM="$2"; shift ;;

    -i|--interactive) INTERACTIVE=YES;; #TODO implement interactive mode

    --default) DEFAULT=YES;;

    -h|--help) HELP=YES;;

    -*) echo >&2 "usage: $0 [--help] [print all options]"
	exit 1;;
    *) echo >&2 "Loading defaults"; DEFAULT=YES;; # terminate while loop
  esac
  shift
  echo "Custom options:" >> "$LOGFILE" 2>&1
  info >> "$LOGFILE" 2>&1
done


if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 $1
fi

#---
# Print Help

if [ "${HELP}" = "YES" ]
  then
    echo -e "$green Print help... $normal"
fi

#---
# Create lock file. Ensure only single instance running.

lock

# Check if the required applications are installed
check_cryptsetup

#---
# Enable it only for testing

echo "System locked, waiting..."
##Sleep 15

#---
# Encrypt volume

encrypt

#---
# Unlock once done.

unlock

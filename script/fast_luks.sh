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
#
# The script is able to detect the $device only if it is mounted. This is by default for our-case.

################################################################################
# VARIABLES

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
# Print out intro banner
function intro(){
  echo -e "$yellow =========================================================$none"
  echo -e "$green \tELIXIR-IIB encryption script - Alpha Version $normal"
  echo -e "$yellow =========================================================$none"
}

#____________________________________
# Lock/UnLock Section
# http://wiki.bash-hackers.org/howto/mutex
# "trap -l" for signal summary

LOCKDIR=/var/run/fast_luks
PIDFILE=${LOCKDIR}/fast-luks.pid

# exit codes and text for them - additional features nobody needs :-)
ENO_SUCCESS=0; ETXT[0]="ENO_SUCCESS"
ENO_GENERAL=1; ETXT[1]="ENO_GENERAL"
ENO_LOCKFAIL=2; ETXT[2]="ENO_LOCKFAIL"
ENO_RECVSIG=3; ETXT[3]="ENO_RECVSIG"


function lock(){

  # start un/locking attempt
  trap 'ECODE=$?; echo "[statsgen] Exit: ${ETXT[ECODE]}($ECODE)" >&2' 0
  echo -n "[$STAT]: " >&2


    if mkdir "${LOCKDIR}" &>/dev/null; then
      # lock succeeded, I'm storing the PID 
      echo "$$" >"${PIDFILE}"
      echo -e "LUKS script for ELIXIR-IIB use case in INDIGO. Starting log file: $now"

    else

      # lock failed, check if the other PID is alive
      OTHERPID="$(cat "${PIDFILE}")"
      # if cat isn't able to read the file, another instance is probably
      # about to remove the lock -- exit, we're *still* locked
      #  Thanks to Grzegorz Wierzowiecki for pointing out this race condition on
      #  http://wiki.grzegorz.wierzowiecki.pl/code:mutex-in-bash
      if [ $? != 0 ]; then
        echo "Another script instance is active: PID ${OTHERPID} " >&2
        exit ${ENO_LOCKFAIL}
      fi

      if ! kill -0 $OTHERPID &>/dev/null; then
        # lock is stale, remove it and restart
        echo "removing fake lock file of nonexistant PID ${OTHERPID}" >&2
        rm -rf "${LOCKDIR}"
        echo "[statsgen] restarting script..." >&2
        exec "$0" "$@"
      else
        # lock is valid and OTHERPID is active - exit, we're locked!
        echo "Lock failed, PID ${OTHERPID} is active" >&2
        echo "Another $STAT process is active" >&2
        echo "If you're sure $STAT is not already running,"
        echo "you can remove $LOCKDIR and restart $STAT" >&2
        exit ${ENO_LOCKFAIL}
      fi
    fi
}

#____________________________________
function unlock(){
  # lock succeeded, install signal handlers before storing the PID just in case 
  # storing the PID fails
  trap 'ECODE=$?;
        echo "[$STAT] Removing lock. Exit: ${ETXT[ECODE]}($ECODE)"  >> "$LOGFILE" 2>&1 
        rm -rf "${LOCKDIR}"' 0

  # the following handler will exit the script upon receiving these signals
  # the trap on "0" (EXIT) from above will be triggered by this trap's "exit" command!
  trap 'echo "[$STAT] Killed by a signal."  >> "$LOGFILE" 2>&1 
        exit ${ENO_RECVSIG}' 1 2 3 15
}


#___________________________________
function info(){
  
  echo -e "#LUKS header information for $device"
  echo -e "#luks-${now}\n"
  
  echo -e "CIPHER_ALGORITHM='${cipher_algorithm}'"
  echo -e "HASH_ALGORITHM='${hash_algorithm}'"
  echo -e "KEYSIZE='${keysize}'"
  echo -e "\n"
  echo "DEVICE='${device}'"
  echo "CRYPTDEV='${cryptdev}'"
  echo "MAPPER='/dev/mapper/${cryptdev}'"
  echo "MOUNTPOINT='${mountpoint}'"
  echo "FILESYSTEM='${filesystem}'"

}

#____________________________________
# Install cryptsetup

function install_cryptsetup(){

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

function check_cryptsetup(){
  echo -e "\n==================================="
  echo -e "Check if the required applications are installed..."
  type -P dmsetup &>/dev/null || echo -e "$red dmestup is not installed. Installing... $noine" #TODO add install device_mapper
  type -P cryptsetup &>/dev/null || { echo -e "$red cryptsetup is not installed. Installing... $none"; install_cryptsetup  >> "$LOGFILE" 2>&1; echo -e "$green cryptsetup installed! $none"; }

}

#____________________________________
# Check volume 

function check_vol(){
  echo -e "\n==================================" >> "$LOGFILE" 2>&1
  echo -e "Check volume..." >> "$LOGFILE" 2>&1

  if [ $(mount | grep -c $mountpoint) == 0 ]; then # grep -c counts recurrence number.
      echo -e "$red Device not mounted, exiting! $none"
      echo "Please check logs: $LOGFILE"
      #---
      # Logs
      echo "Error: no device  mounted to $mountpoint:" >> "$LOGFILE" 2>&1
      df -h >> "$LOGFILE" 2>&1
      # end logs
      unlock # unlocking script instance
      exit 1
  else
    device=$(df -P $mountpoint | tail -1 | cut -d' ' -f 1)
    echo "Device name: $device" >> "$LOGFILE" 2>&1
  fi
}


#____________________________________
# Umount volume

function umount_vol(){
  echo -e  "\n==================================="
  echo "Umounting device..."
  umount $mountpoint
  echo "$device umounted, ready for encryption!"
}


#____________________________________
function setup_device(){
  echo -e "\n==================================="
  echo "Using the selected $cipher_algorithm algorithm to luksformat the volume"
  #---
  # log
  echo -e "\nStart cryptsetup" >> "$LOGFILE" 2>&1
  info >> "$LOGFILE" 2>&1
  echo -e "cryptsetup full command:" >> "$LOGFILE" 2>&1 
  echo -e "cryptsetup -v --cipher $cipher_algorithm --key-size $keysize --hash $hash_algorithm --iter-time 2000 --use-urandom --verify-passphrase luksFormat $device" >> "$LOGFILE" 2>&1 
  # end log
  cryptsetup -v --cipher $cipher_algorithm --key-size $keysize --hash $hash_algorithm --iter-time 2000 --use-urandom --verify-passphrase luksFormat $device
  ecode=$?
  if [ $ecode != 0 ]; then
    # log
    echo -e "Error: Command cryptsetup failed! Mounting $device to $mountpoint again." >> "$LOGFILE" 2>&1 #TODO redirect exit code
    mount $device $mountpoint >> "$LOGFILE" 2>&1
    # end log
    unlock
    exit 1
  fi
}


#____________________________________
function open_device(){
  echo -e "\n==================================="
  echo -e "Open LUKS volume"
  if [ ! -b /dev/mapper/${cryptdev} ]; then
    cryptsetup luksOpen $device $cryptdev
  else
    echo -e "$red Crypt device already exists! Please check logs: $LOGFILE $none"
    # log
    echo -e "\nError: Unable to luksOpen device. " >> "$LOGFILE" 2>&1
    echo -e "Error: /dev/mapper/${cryptdev} already exists." >> "$LOGFILE" 2>&1
    echo -e " Mounting $device to $mountpoint again." >> "$LOGFILE" 2>&1
    mount $device $mountpoint >> "$LOGFILE" 2>&1
    # end log
    unlock # unlocking script instance
    exit 1
  fi
}


#____________________________________
function encryption_status(){
  echo "==================================="
  echo "check $cryptdev status with cryptseutp status"
  cryptsetup -v status $cryptdev
}


#____________________________________
# Create block file
# https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption
# https://wiki.archlinux.org/index.php/Dm-crypt/Drive_preparation
# https://wiki.archlinux.org/index.php/Disk_encryption#Preparing_the_disk
#
# Before encrypting a drive, it is recommended to perform a secure erase of the disk by overwriting the entire drive with random data.
# To prevent cryptographic attacks or unwanted file recovery, this data is ideally indistinguishable from data later written by dm-crypt.

function wipe_data(){
  echo -e "\n==================================="
  echo "Wiping disk data by overwriting the entire drive with random data"
  echo "This might take time depending on the size & your machine!"

  #dd if=/dev/zero of=/dev/mapper/${cryptdev} bs=1M  status=progress >> "$LOGFILE" 2>&1
  pv -tpreb /dev/zero | dd of=/dev/mapper/${cryptdev} bs=1M status=progress >> "$LOGFILE" 2>&1
  echo -e "\nBlock file /dev/mapper/${cryptdev} created." >> "${LOGFILE}" 2>&1
  echo -e "Wiping done."
}


#____________________________________
function create_fs(){
  echo -e "\n==================================="
  echo -e "Creating filesystem..."
  mkfs.${filesystem} /dev/mapper/${cryptdev} #Do not redirect mkfs, otherwise no interactive mode!
  if [ $? != 0 ]; then
    echo -e "$red Error: while creating ${filesystem} filesystem. Please check logs: $LOGFILE $none"
    # log
    echo -e "Error: Command mkfs failed!" >> "$LOGFILE" 2>&1 #TODO redirect log
    # end log
    unlock
    exit 1
  fi

}


#____________________________________
function mount_vol(){

  echo -e "\n==================================="
  echo -e "Mounting encrypted device..."
  mount /dev/mapper/${cryptdev} $mountpoint
  df -Hv >> "$LOGFILE" 2>&1

}


#____________________________________
function save_info(){

  # Create crypdev conf file
  luks_cryptdev_file='/etc/luks-cryptdev.conf'
  echo -e "# This file has been generated using fast_luks.sh script: https://github.com/mtangaro/galaxycloud-testing/blob/master/fast_luks.sh" > ${luks_cryptdev_file}
  echo -e "# The device name could change after reboot, please use UUID instead." >> ${luks_cryptdev_file}
  echo -e "# LUKS provides a UUID \(Universally Unique Identifier\) \for each device. This, unlike the device name \(eg: /dev/vdb\), is guaranteed to remain constant as long as the LUKS header remains intact.\n" >> ${luks_cryptdev_file}
  info >> ${luks_cryptdev_file}
  uuid=$(cryptsetup luksUUID ${device})
  echo -e "UUID='${uuid}'" >> ${luks_cryptdev_file}

  # Update Log file
  dmsetup info /dev/mapper/${cryptdev} >> "$LOGFILE" 2>&1
  cryptsetup luksDump $device >> "$LOGFILE" 2>&1
}


#____________________________________
function __end(){
  # send signal to unclok waiting condition for automation software (e.g Ansible)
  echo -e "LUKS encryption completed." > $SUCCESS_FILE
  echo -e "\n$green Successful. Please exit by the VM/Docker. Galaxy will be automatically installed! $none"
}


#____________________________________
#FIXME cryptsetup (temporary version)

function encrypt(){

  # Check which virtual volume is mounted to /export
  check_vol

  # Umount volume.
  umount_vol  >> "$LOGFILE" 2>&1

  # Setup a new dm-crypt device
  setup_device

  # Create mapping
  open_device

  # Check status
  encryption_status >> "$LOGFILE" 2>&1
  
  # Wipe data for security
  wipe_data

  # Create filesystem
  create_fs

  # Mount volume
  mount_vol

  # Print logs and luks information file on /etc
  save_info

}



################################################################################
# Main script

STAT="fast-luks"
LOGFILE="/tmp/luks$now.log"
SUCCESS_FILE="/tmp/fast-luks.success"

# Default values
cipher_algorithm='aes-xts-plain64'
keysize='256'
hash_algorithm='sha256'
device='/dev/vdb'
cryptdev='crypt'
mountpoint='/export'
filesystem='ext4'

#---
# Create lock file. Ensure only single instance running.
lock >> "$LOGFILE" 2>&1

#---
# Print intro
intro

# If running script with no arguments then loads defaults values.
if [ $# -lt 1 ]; then
  echo -e "\nNo inputs. Using defaults values:" >> "$LOGFILE" 2>&1
  info >> "$LOGFILE" 2>&1
fi


# Parse CLI options

while [ $# -gt 0 ]
do

  case $1 in
    -c|--cipher) cipher_algorithm="$2"; shift;;
    
    -k|--keysize) keysize="$2"; shift;;

    -a|--hash_algorithm) hash_algorithm="$2"; shift;;

    -d|--device) device="$2"; shift ;;

    -e|--cryptdev) cryptdev="$2"; shift ;;

    -m|--mountpoint) mountpoint="$2"; shift ;;

    -p|--passphrase) passphrase="$2"; shift ;;  #TODO to be implemented passphrase option for web-UI

    -f|--filesystem) filesystem="$2"; shift ;;

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
# Check if the required applications are installed
check_cryptsetup

#---
# Encrypt volume
encrypt

#---
# LUKS encryption finished. Print end dialogue.
__end

#---
# Unlock once done.
unlock >> "$LOGFILE" 2>&1

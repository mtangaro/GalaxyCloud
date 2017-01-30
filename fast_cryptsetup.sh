#!/bin/bash


#____________________________________
LOG_FILE="/tmp/fast_cryptsetup.log"

#exec 3>&1 1>>${LOG_FILE} 2>&1


################################################################################
# colors for errors and warnings	
red=$(tput setab 0; tput setaf 1)
yellow=$(tput setab 0; tput setaf 3)
none=$(tput sgr0)

# colors for messages
green="\033[32m"
blue="\033[34m"
normal="\033[0m"


################################################################################




################################################################################
# Parse CLI options

while [ $# -gt 0 ]
do

  case $1 in
    -c|--cipher) CIPHER="$2"; shift;;

    -d|--device) DEVICE="$2"; shift ;;

    -a|--address) ADDRESS="$2"; shift ;;

    -m|--mountpoint) MOUNTPOINT="$2"; shift ;;

    -p|--passphrase) PASSPHRASE="$2"; shift ;;

    -i|--interactive) INTERACTIVE=YES;;

    --default) DEFAULT=YES;;

    -h|--help) HELP=YES;;

    -*) echo >&2 "usage: $0 [--help] [print all options]"
	exit 1;;
    *) echo >&2 "Loading defaults"; DEFAULT=YES;;	# terminate while loop
  esac
  shift
done

echo CIPHER  = "${CIPHER}"
echo DEVICE PATH  = "${DEVICE}"
echo MAPPER PATH  = "${ADDRESS}"
echo MOUNTPOINT  = "${MOUNTPOINT}"
echo DEFAULT = "${DEFAULT}"

if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 $1
fi

#---
# Print Help

#---
# Default Options

if [ "${HELP}" = "YES" ]
  then
    echo -e "$green Print help... $normal"
fi

if [ "${DEFAULT}" = "YES" ]
  then
    echo -e "$blue Setting to default... $normal"
fi



function check_cryptsetup {
i
  if [[ -r /etc/os-release ]]; then
      . /etc/os-release
      echo $ID  | tee /dev/fd/3
      if [ "$ID" = "ubuntu" ]; then
          echo "Distribution: Ubuntu. Using apt" | tee /dev/fd/3
          apt-get install -y cryptsetup  | tee /dev/fd/3
      else
          echo "Distribution: CentOS. Using yum"  | tee /dev/fd/3
          yum install -y cryptsetup-luks pv | tee /dev/fd/3
      fi
  else
      echo "Not running a distribution with /etc/os-release available" | tee /dev/fd/3
  fi

}


###
#cryptsetup -y -v luksFormat /dev/vdb
#
#cryptsetup luksOpen /dev/vdb galaxy_data
#
#cryptsetup -v status galaxy_data
#
#cryptsetup luksDump /dev/vdb
#
#dd if=/dev/zero of=/dev/mapper/galaxy_data
#
#pv -tpreb /dev/zero | dd of=/dev/mapper/galaxy_data bs=128M
#
#mkfs.ext4 /dev/mapper/galaxy_data
#
#mount /dev/mapper/galaxy_data /export

#df -H


#check_cryptsetup

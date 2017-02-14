#!/bin/bash

#---
# Reference data space is always mounted to $REFDATA_DIR

#REFDATA_DIR="/refdata"

#ONECLIENT_AUTHORIZATION_TOKEN=MDAxNWxvY2F00aW9uIG9uZXpvbmUKMDAzYmlkZW500aWZpZXIgbVVfYjRpZUt4WGZtbVBWMG0000QjhURzNPUEJhdVJFS3NybGduU00ZGYWkwbwowMDFhY2lkIHRpbWUgPCAxNTEzOTQxMjc3CjAwMmZzaWduYXR1cmUgNZ00sfBXZuuS3Q7I00A02qNe4rWw6lAWPJdYpor46u6Q7AK

#PROVIDER_HOSTNAME=cdmi-indigo.recas.ba.infn.it

#oneclient --authentication token /refdata

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



function connect(){

ONECLIENT_AUTHORIZATION_TOKEN=$access_token

PROVIDER_HOSTNAME=$provider

oneclient --authentication token $mountpoint

}


function create_config_file(){
  echo "TBU"
}

#---
# User data space

#if [


config_file='/etc/onedata-spaces.conf'


# Parse CLI options
while [ $# -gt 0 ]
do

  case $1 in
    -c|--config) config_file=$2; shift;;

    -r|--refdata) refdata=true;;

    -u|--userdata) userdata=true;;

    -a|--auth-token) access_token=$2; shift;;

    -p|--provider-hostname) provider=$2; shift;;

    -m|--mountpoint) mountpoint=$2; shift;;

    -h|--help) HELP=YES;;

    -*) echo >&2 "usage: $0 [--help] [print all options]"
        exit 1;;
  esac
  shift
done


if [ -z $config_file ]; then
  echo "var is unset"
else
  source ${config_file}
fi

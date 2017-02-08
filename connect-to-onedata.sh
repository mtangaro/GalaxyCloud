#!/bin/bash

#---
# Reference data space is always mounted to $REFDATA_DIR

#REFDATA_DIR="/refdata"

#ONECLIENT_AUTHORIZATION_TOKEN=MDAxNWxvY2F00aW9uIG9uZXpvbmUKMDAzYmlkZW500aWZpZXIgbVVfYjRpZUt4WGZtbVBWMG0000QjhURzNPUEJhdVJFS3NybGduU00ZGYWkwbwowMDFhY2lkIHRpbWUgPCAxNTEzOTQxMjc3CjAwMmZzaWduYXR1cmUgNZ00sfBXZuuS3Q7I00A02qNe4rWw6lAWPJdYpor46u6Q7AK

#PROVIDER_HOSTNAME=cdmi-indigo.recas.ba.infn.it

#oneclient --authentication token /refdata


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
  echo "var is set to '$config_file'"
fi

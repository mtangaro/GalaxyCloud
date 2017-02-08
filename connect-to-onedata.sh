#!/bin/bash

#---
# Reference data space is always mounted to $REFDATA_DIR

REFDATA_DIR="/refdata"

ONECLIENT_AUTHORIZATION_TOKEN=MDAxNWxvY2F00aW9uIG9uZXpvbmUKMDAzYmlkZW500aWZpZXIgbVVfYjRpZUt4WGZtbVBWMG0000QjhURzNPUEJhdVJFS3NybGduU00ZGYWkwbwowMDFhY2lkIHRpbWUgPCAxNTEzOTQxMjc3CjAwMmZzaWduYXR1cmUgNZ00sfBXZuuS3Q7I00A02qNe4rWw6lAWPJdYpor46u6Q7AK

PROVIDER_HOSTNAME=cdmi-indigo.recas.ba.infn.it

oneclient --authentication token /refdata


#---
# User data space

#if [


# Parse CLI options
while [ $# -gt 0 ]
do

  case $1 in
    -r|--refdata) REFDATA=YES;;

    -t|--refdata-access-token) REFDATA_ACCESS_TOKEN=$2; shift;;

    -p|--refdata-provider-hostname) REFDATA_PROVIDER_HOSTNAME=$2; shift;;

    -m|--refdata-mountpoint) REFDATA_DIR=$2; shift;;

    -u|--userdata) USERDATA=YES;;

    -a|--userdata-access-token) keysize="$2"; shift;;

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


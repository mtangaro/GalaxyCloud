#!/bin/bash

# Galaxy central management tool
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




################################################################################
# GALAXY FUNCTIONS


#____________________________________
# Load Galaxy environment

function __load_galaxy_env(){
  echo -e "\nLoading Galaxy environment"
  cd /home/galaxy/galaxy
  . /home/galaxy/galaxy/.venv/bin/activate
}


#____________________________________
# Check if supervisord is running
# Following the Unix convention of expecting utilities to return zero for success and non-zero for failure, so boolean conditions are inverted.

function __check_supervisord(){
  if ps ax | grep -v grep | grep supervisord > /dev/null
  then
    echo "Supervisord service running, everything is fine."
    return 0
  else
    echo "supervisord is not running."
    return 1
  fi
}


#____________________________________
# Check if Galaxy instance is up

function __galaxy_url_status(){
  if curl -s --head  --request GET http://90.147.102.96/galaxy | grep "200 OK" > /dev/null; then 
    echo -e "$green""GALAXY IS UP AND RUNNING""$none"
  else
    echo -e "$red""GALAXY IS DOWN""$none"
  fi

}



#____________________________________
# Check if Galaxy instance is up

function __galaxy_server_status(){
  supervisorctl status galaxy:
}


#____________________________________

function __galaxy_ps(){
  ps -aux | grep "uwsgi"
}


#____________________________________
# Check if Galaxy instance is up

function __galaxy_status(){
  echo -e "\nUrl status:"; __galaxy_url_status
  echo -e "\nSupervisctl status:"; __galaxy_server_status
  echo -e "\nuWSGI status:"; __galaxy_ps
}


#____________________________________
# Define start function
function __start_galaxy(){
  __load_galaxy_env

  if __check_supervisord ; then
    echo -e "\nStarting Galaxy"
    supervisorctl start galaxy:
  else
    echo -e "\nStarting supervisord, Galaxy will be automatically started."
    /usr/bin/supervisord
  fi
}


#____________________________________
# Define stop function

function __stop_galaxy(){
  __load_galaxy_env

  echo -e "\nStopping galaxy from supervisord"
  supervisorctl stop galaxy:

  echo -e "\nuWSGI nodes check"
  if [ "$(pidof uwsgi)" ]
  then
  # process was found
  echo -e "\nKilling uwsgi residual nodes"
  kill -9 $(pidof uwsgi)
  else
  # process not found
  echo -e "\nuWSGI already gracefully stopped"
  fi
}


#____________________________________
# Define restart function

function __restart_galaxy(){
  echo -e "\nRestarting the Galaxy production environment"
  __stop_galaxy
  __start_galaxy
}


if [ "$1" == "galaxy" ]; then
  if [ "$2" == "start" ]; then __start_galaxy; fi
  if [ "$2" == "stop" ]; then __stop_galaxy; fi
  if [ "$2" == "restart" ]; then __restart_galaxy; fi
  if [ "$2" == "status" ]; then __galaxy_status; fi
  if [ "$2" == "ps" ]; then __galaxy_ps; fi
  if [ "$2" == "load_env" ]; then __load_galaxy_env; fi
fi


################################################################################
# STORAGE FUNCTIONS


#____________________________________
# check encrypted storage mounted

function check_cryptdev(){

  echo "TBU"

}

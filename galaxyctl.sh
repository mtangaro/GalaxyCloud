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
# FUNCTIONS


#____________________________________
# Load Galaxy environment

function __load_galaxy_env(){
  echo -e "Loading Galaxy environment"
  cd /home/galaxy/galaxy
  . /home/galaxy/galaxy/.venv/bin/activate
}


#____________________________________
# Define start function
function __start_galaxy(){
  _load_galaxy_env

  echo -e "Start Galaxy"
  supervisorctl start galaxy:
}


#____________________________________
# Define stop function

function __stop_galaxy(){
  __load_galaxy_env

  echo -e "Stop galaxy from supervisord"
  supervisorctl stop galaxy:

  echo -e "uWSGI nodes check"
  if [ "$(pidof uwsgi)" ]
  then
  # process was found
  echo -e "Killing uwsgi residual nodes"
  kill -9 $(pidof uwsgi)
  else
  # process not found
  echo -e "uWSGI already gracefully stopped"
  fi
}


#____________________________________
# Define restart function

function __restart_galaxy(){
  echo -e "Restarting the Galaxy production environment"
  __stop_galaxy
  __start_galaxy
}


if [ "$1" == "galaxy" ]; then
  if [ "$2" == "restart" ]; then __restart_galaxy; fi
fi

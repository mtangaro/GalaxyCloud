#!/bin/bash

# ELIXIR-ITALY
# INDIGO-DataCloud
# IBIOM-CNR
#
# Contributors:
# author: Tangaro Marco
# email: ma.tangaro@ibiom.cnr.it

# Script based on install_tools_wrapper from B. Gruening and adpted to our ansible roles.
# https://raw.githubusercontent.com/bgruening/docker-galaxy-stable/master/galaxy/install_tools_wrapper.sh

GALAXY='/home/galaxy/galaxy'
GALAXY_USER='galaxy'
install_log='/var/log/galaxy/galaxy_tools_install.log'
install_pidfile='/var/log/galaxy/galaxy_tools_install.pid'

#________________________________
function check_postgresql_vm {

  # Check if postgresql is running
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo $ID
    if [ "$ID" = "ubuntu" ]; then
      echo "[Ubuntu] Check postgresql."
      if [ "$VERSION_ID" = "16.04"]; then
        service start postgresql
      else
        systemctl start postgresql
      fi
    elif [ "$ID" = "centos" ]; then
      echo "[EL] Check postgresql"
      systemctl start postgresql-9.6
    fi
  fi
}

function check_postgresql_docker {
  echo 'placeholder'
}

function check_postgresql {

  check_postgresql_vm # selection between vm and docker will be done at ansible level.

  # wait for database to finish starting up
  STATUS=$(psql 2>&1)
  while [[ ${STATUS} =~ "starting up" ]]
  do
    echo "waiting for database: $STATUS"
    STATUS=$(psql 2>&1)
    sleep 1
  done
}

#________________________________
# clean logs
#rm $install_log
#rm $install_pidfile

# ensure Galaxy is not running through supervisord
if pgrep "supervisord" > /dev/null
then
    echo "Galaxy managed using supervisord. Shutting it down."
    supervisorctl stop galaxy:
fi

# check PostgreSQL
check_postgresql

# stop nginx allowing to connect on port 80
echo "[VM] Stop NGINX. Freeing port 80."
nginx -s stop

#echo "[Docker] Start NGINX"
#supervisorctl stop nginx

# create log file
sudo -E -u $GALAXY_USER touch $install_log
 
# start Galaxy
export PORT=8080
echo "starting Galaxy"
sudo -E -u $GALAXY_USER $GALAXY/run.sh --daemon --log-file=$install_log --pid-file=$install_pidfile

# wait galaxy to start
galaxy_install_pid=`cat $install_pidfile`
echo $galaxy_install_pid

while : ; do
  tail -n 2 $install_log | grep -E -q "Removing PID file galaxy_install.pid|Daemon is already running"
  if [ $? -eq 0 ] ; then
    echo "Galaxy could not be started."
    echo "More information about this failure may be found in the following log snippet from galaxy_install.log:"
    echo "========================================"
    tail -n 60 $install_log
    echo "========================================"
    echo $1
    exit 1
  fi
  tail -n 2 $install_log | grep -q "Starting server in PID $galaxy_install_pid"
  if [ $? -eq 0 ] ; then
    echo "Galaxy is running."
    break
  fi
done

# install tools
shed-install -g "http://localhost:$PORT" -a GALAXY_ADMIN_API_KEY -t "$1"

exit_code=$?

if [ $exit_code != 0 ] ; then
    exit $exit_code
fi

# stop Galaxy
echo "stopping Galaxy"
sudo -E -u $GALAXY_USER $GALAXY/run.sh --stop-daemon --log-file=$install_log --pid-file=$install_pidfile

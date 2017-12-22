#!/bin/bash

LOGFILE="/tmp/setup.log"
now=$(date +"-%b-%d-%y-%H%M%S")
echo "Start log ${now}" > $LOGFILE

#________________________________
# Get Distribution

DISTNAME=''
if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo $ID > $LOGFILE
    if [ "$ID" = "ubuntu" ]; then
      echo 'Distribution Ubuntu' > $LOGFILE
      DISTNAME='ubuntu'
    else
      echo 'Distribution: CentOS' > $LOGFILE
      DISTNAME='centos'
    fi
else
    echo "Not running a distribution with /etc/os-release available" > $LOGFILE
fi


#________________________________
# Install depdendencies

if [ "$DISTNAME" = "ubuntu" ]; then
  echo "Distribution: Ubuntu. Using apt" >> $LOGFILE
  apt-get -y update &>> $LOGFILE
  apt-get install -y python-pip python-dev libffi-dev libssl-dev &>> $LOGFILE
  apt-get -y install git vim python-pycurl wget &>> $LOGFILE
else
  echo "Distribution: CentOS. Using yum" >> $LOGFILE
  yum install -y epel-release &>> $LOGFILE
  yum update -y &>> $LOGFILE
  yum groupinstall -y "Development Tools" &>> $LOGFILE
  yum install -y python-pip python-devel libffi-devel openssl-devel &>> $LOGFILE
  yum install -y  git vim python-curl wget  &>> $LOGFILE
fi

#________________________________
# Install cvmfs packages

echo 'Install cvmfs client' &>> $LOGFILE
if [ "$DISTNAME" = "ubuntu" ]; then
  echo "Distribution: Ubuntu." >> $LOGFILE
  wget https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest_all.deb -O /tmp/cvmfs-release-latest_all.deb &>> $LOGFILE
  sudo dpkg -i /tmp/cvmfs-release-latest_all.deb &>> $LOGFILE
  rm -f /tmp/cvmfs-release-latest_all.deb &>> $LOGFILE
  sudo apt-get update &>> $LOGFILE
  apt-get install -y cvmfs cvmfs-config-default &>> $LOGFILE
else
  echo "Distribution: CentOS." >> $LOGFILE
  yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm &>> $LOGFILE
  yum install -y cvmfs cvmfs-config-default &>> $LOGFILE
fi

#________________________________
# Clean youm cache

if [ "$DISTNAME" = "ubuntu" ]; then
  apt-get clean
else
  yum clean all
fi

#________________________________
# Remove cloud-init artifact
# you can't remove cloud-init artifact using this script
# since it is using cloudinit to run :)
# so this is commented out.
#echo 'Removing cloud-init artifact' &>> $LOGFILE
#rm -rf /var/lib/cloud/* &>> $LOGFILE
#rm /var/log/cloud-init.log &>> $LOGFILE
#rm /var/log/cloud-init-output.log &>> $LOGFILE

#________________________________
# Remove cloud-init user

#if [ "$DISTNAME" = "ubuntu" ]; then
#  userdel -r -f ubuntu
#else
#  userdel -r -f centos
#fi

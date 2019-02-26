#!/bin/bash

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo $ID &>> $LOGFILE
    if [ "$ID" = "ubuntu" ]; then
      echo 'Distribution Ubuntu. Installing ansible'

      sudo apt-get -y update &&\
      sudo apt-get -y install software-properties-common &&\
      sudo apt-add-repository --yes --update ppa:ansible/ansible &&\
      sudo apt-get -y install ansible

    else
      echo 'Distribution: CentOS'
      echo 'To be implemented'
    fi
else
    echo "Not running a distribution with /etc/os-release available"
fi

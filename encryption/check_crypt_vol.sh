#!/bin/bash

#1. mail al riavvio

#2. lista delle chiavi root e galaxy




#"elixir-italy.galaxy.refdata server was rebooted at: $(date)" | /usr/bin/mail -s "[reboot] elixir-italy.galaxy.refdata"  ma.tangaro@gmail.com

#________________________________
# Get Distribution
if [[ -r /etc/os-release ]]; then
    . /etc/os-release
fi

#________________________________
# Install mail
function install_mail {

  if [[ $ID = "ubuntu" ]]; then
    apt-get install -y mailutils
  elif [[ $ID = "centos" ]]; then
    yum install -y mailx
  else
    echo "Not supported distribution"
    exit 1
  fi

}

#________________________________
#________________________________

SUBJECT='soggetto'
MAILADDR='ma.tangaro@gmail.com'
MAILFROM='laniakea@elixir-italy.org'

install_mail

echo "Please ssh into your Galaxy instance: ssh -i <private_key> galaxy@{{ ansible_default_ipv4.address }} and and follow the instructions " | mail -s "$SUBJECT" $MAILADDR -- -f $MAILFROM

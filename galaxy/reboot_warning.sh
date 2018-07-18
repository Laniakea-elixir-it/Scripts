#!/bin/bash

OS_STORAGE='encryption'
IPADDR='90.147.170.148'
SUBJECT="[Reboot] Your Galaxy server at $IPADDR has been restarted."
MAILADDR="ma.tangaro@gmail.com"
MAILFROM="laniakea@elixir-italy.org"

#"elixir-italy.galaxy.refdata server was rebooted at: $(date)" | /usr/bin/mail -s "[reboot] elixir-italy.galaxy.refdata"  ma.tangaro@gmail.com

#________________________________
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

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
  elif [[ $ID = "centos" ]]; then
    yum install -y mailx
  else
    echo "Not supported distribution"
    exit 1
  fi

}

#________________________________
#________________________________

if [[ $OS_STORAGE == "encryption" ]]; then

BODY="
Dear User,
this is an automatically generated notification mail
YOU DO NOT NEED ANSWER TO THIS MESSAGE

You received this e-mail because your virtual Galaxy (http://$IPADDR/galaxy) server has been restarted.
Since you are using an encrypted instance you have to insert your passphrase to enable your volume before starting Galaxy.

Please ssh into your Galaxy instance using the {{ galaxy_user }} user:
ssh -i your_private_key galaxy@$IPADDR

Type
\"sudo luksctl open\"
and insert your passphrase.

Finally you can restart Galaxy, typing
\"sudo galaxy-startup\"

We report here root and galaxy authorized keys content. Please check if undesired ssh keys have been injected:

=============================================================
ROOT

$(cat /root/.ssh/authorized_keys)

=============================================================
GALAXY

$(cat /home/galaxy/.ssh/authorized_keys)

Kind Regards.
"

elif [[ $OS_STORAGE == "IaaS" ]]; then

BODY="
Dear User,
this is an automatically generated notification mail
YOU DO NOT NEED ANSWER TO THIS MESSAGE

You received this e-mail because your virtual Galaxy (http://$IPADDR/galaxy) server has been restarted.


Kind Regards.
"

fi

#________________________________
#________________________________

install_mail

#echo "Please ssh into your Galaxy instance: ssh -i <private_key> galaxy@$IPADDR and and follow the instructions " | mail -s "$SUBJECT" $MAILADDR -- -f $MAILFROM

if [[ $ID == "ubuntu" ]]; then

  echo $BODY | mail -s "$SUBJECT" $MAILADDR -- -f $MAILFROM

elif [[ $ID == 'centos' ]]; then

  echo "$BODY" | mail -r $MAILFROM -s "$SUBJECT" $MAILADDR

fi

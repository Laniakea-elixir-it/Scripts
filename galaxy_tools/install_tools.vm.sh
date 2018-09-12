#!/bin/bash

# ELIXIR-ITALY
# IBIOM-CNR
#
# Contributors:
# author: Tangaro Marco
# email: ma.tangaro@ibiom.cnr.it

# Script based on install_tools_wrapper from B. Gruening and adpted to our ansible roles.
# https://raw.githubusercontent.com/bgruening/docker-galaxy-stable/master/galaxy/install_tools_wrapper.sh

# Usage: install-tools GALAXY_ADMIN_API_KEY tool-list.yml

GALAXY='/home/galaxy/galaxy'
GALAXY_USER='galaxy'
#---
now=$(date +"%b-%d-%y-%H%M%S")
install_log="/var/log/galaxy/galaxy_tools_install_$now.log"
install_pidfile='/var/log/galaxy/galaxy_tools_install.pid'
#---
postgresql_version='9.6'
#---
ephemeris_version='0.9.0'

#________________________________
# Get Distribution
if [[ -r /etc/os-release ]]; then
    . /etc/os-release
fi

#____________________________________
# Script needs superuser
function su_check {
  if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo -e "[Error] Not running as root."
    exit
 fi
}

#________________________________
# Check if postgresql is running
function start_postgresql_vm {

  if [[ $ID = "ubuntu" ]]; then
    echo "[Ubuntu][VM] Check postgresql."
    if [[ $VERSION_ID = "16.04" ]]; then
      service start postgresql
    else
      systemctl start postgresql
    fi
  elif [[ $ID = "centos" ]]; then
      echo "[EL][VM] Check postgresql"
      systemctl start postgresql-${postgresql_version}
  fi
}

#________________________________
function start_postgresql_docker {

  if [[ $ID = "ubuntu" ]]; then
    echo "[Ubuntu][Docker] Check postgresql."
    service start postgresql
  elif [ "$ID" = "centos" ]; then
    echo "[EL][Docker] Check postgresql"
    if [[ ! -f /var/lib/pgsql/${postgresql_version}/data/postmaster.pid ]]; then
      echo "Starting postgres on centos"
      sudo -E -u postgres /usr/pgsql-${postgresql_version}/bin/pg_ctl -D /var/lib/pgsql/${postgresql_version}/data -w start
    fi
  fi

}

#________________________________
function check_postgres_status {

  PGUSER="${PGUSER:="postgres"}"

  if [[ $ID = "ubuntu" ]]; then
    echo 'placeholder'
  elif [ "$ID" = "centos" ]; then
    /usr/pgsql-${postgresql_version}/bin/pg_isready -U "$PGUSER" -q
    DATA=$?
  fi

}

#________________________________
function check_postgresql {

  start_postgresql_vm

  check_postgres_status

  # wait for database to finish starting up
  while [[ ${DATA}  != 0 ]]
  do
    echo "waiting for database."
    check_postgres_status
    sleep 1
  done
}

#________________________________
# Install lsof

function install_lsof {
  if [[ $ID = "ubuntu" ]]; then
    echo "[Ubuntu] Installing lsof with apt."
    apt-get install -y lsof
  else
    echo "[EL] Installing lsof with yum."
    yum install -y lsof
  fi
}

function check_lsof {
  type -P lsof &>/dev/null || { echo "lsof is not installed. Installing.."; install_lsof; }
}

#________________________________
function install_ephemeris {
  echo "Load clean virtual environment"
  virtualenv /tmp/tools_venv
  source /tmp/tools_venv/bin/activate
  echo "Install ephemeris using pip in the clean environment"
  pip install bioblend
  pip install ephemeris==$ephemeris_version
}

#________________________________
#________________________________
#________________________________
# Main section

# Script requires superuser to run
su_check

# clean logs
echo "Clean logs"
rm $install_log
rm $install_pidfile

# install ephemeris
install_ephemeris

# check PostgreSQL
check_postgresql

# If Galaxy is running we install tools, otherwise we run int through run.sh
if pgrep "supervisord" > /dev/null
then

  echo "Galaxy managed using supervisord. Shutting it down."
  supervisorctl stop galaxy:
fi

# ensure galaxy is not running on run.sh and 8080 port
check_lsof
echo "Kill run.sh Galaxy instance listening on 8080 port"
kill -9 $(lsof -t -i :8080)

# create log file
sudo -E -u $GALAXY_USER touch $install_log
 
# start Galaxy
export PORT=8080
echo "starting Galaxy"
sudo -E -u $GALAXY_USER $GALAXY/run.sh -d $install_log --pidfile $install_pidfile  --http-timeout 3000

# wait galaxy to start
galaxy_install_pid=`cat $install_pidfile`
galaxy-wait -g http://localhost:$PORT -v --timeout 120

# install tools
#shed-tools install -g "http://localhost:$PORT" -a $1 -t "$2"
# workaround to https://github.com/galaxyproject/ephemeris/issues/98
counter=0
output=$(shed-tools install -g "http://localhost:$PORT" -a $1 -t "$2" 2>&1)
while [[ $output == *'ConnectionError'* ]]; do
  echo $output
  ((counter++))
  echo "Retry: $counter"
  sleep 60 # wait for unfinished operations
  output=$(shed-tools install -g "http://localhost:$PORT" -a $1 -t "$2" 2>&1)
done

exit_code=$?

if [ $exit_code != 0 ] ; then
    exit $exit_code
fi

# stop Galaxy if it was not running before
if ! pgrep "supervisord" > /dev/null
then
  echo "stopping Galaxy"
  sudo -E -u $GALAXY_USER $GALAXY/run.sh --stop $install_pidfile


fi

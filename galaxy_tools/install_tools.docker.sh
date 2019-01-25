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
ephemeris_log="/tmp/ephemeris_$now.log"
#---
postgresql_version='9.6'
#---
ephemeris_version='0.9.0'

#########
# Galaxy configuration variables
# Do not change this values.
export GALAXY_CONFIG_FILE='/tmp/galaxy.lite.yml'
export GALAXY_CONFIG_DATABASE_CONNECTION='postgresql://galaxy:galaxy@localhost:5432/galaxy'
export GALAXY_CONFIG_INSTALL_DATABASE_CONNECTION='postgresql://galaxy:galaxy@localhost:5432/galaxy_tools'
export GALAXY_CONFIG_TOOL_DEPENDENCY_DIR='/export/tool_deps'
export GALAXY_CONDA_PREFIX='/export/tool_deps/_conda'
DEFAULT_JOB_CONF=/home/galaxy/galaxy/config/job_conf.xml.sample_basic
export GALAXY_CONFIG_JOB_CONFIG_FILE=$DEFAULT_JOB_CONF
export GALAXY_CONFIG_ADMIN_USERS='admin@elixir-italy.org'
#########

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
    if [[ $VERSION_ID = "14.04" ]]; then
      service postgresql start
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
    /usr/lib/postgresql/${postgresql_version}/bin/pg_isready -U "$PGUSER" -q
  elif [ "$ID" = "centos" ]; then
    /usr/pgsql-${postgresql_version}/bin/pg_isready -U "$PGUSER" -q
    DATA=$?
  fi

}

#________________________________
function check_postgresql {

  start_postgresql_docker

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

# create galaxy.yml file.
# The extension of the config file is used by yaml parser
# it is not possible to exploit the galaxy.yml.sample file directly
cp $GALAXY/config/galaxy.yml.sample $GALAXY_CONFIG_FILE

# If Galaxy is running we install tools, otherwise we run int through run.sh
if pgrep "supervisord" > /dev/null
then
  echo "Galaxy managed using supervisord. Shutting it down."
  supervisorctl stop galaxy:
fi

# ensure galaxy is not running on run.sh and 8080 port
check_lsof
echo "Kill run.sh Galaxy instance listening on 8080 port and 4001 for uwsgi."
kill -9 $(lsof -t -i :8080)
kill -9 $(lsof -t -i :4001) # clean running uwsgi instances.
# create log file
sudo -E -u $GALAXY_USER touch $install_log
 
# start Galaxy
export PORT=8080
echo "Starting Galaxy"
sudo -E -u $GALAXY_USER $GALAXY/run.sh -d $install_log --pidfile $install_pidfile  --http-timeout 3000

# wait galaxy to start
galaxy_install_pid=`cat $install_pidfile`
galaxy-wait -g http://localhost:$PORT -v --timeout 3000 #120

# install tools using ephemeris
# usage: shed-tools install -g "http://localhost:$PORT" -a $1 -t "$2" --log_file $ephemeris_log
# Currently ephemeris has 2 bug:
# 1. exit without errors during tools install
# 2. https://github.com/galaxyproject/ephemeris/issues/98
# as workaround we restart ephemeris up to 3 times
#counter=0
#COUNT=3
#output=$(shed-tools install -g "http://localhost:$PORT" -a $1 -t "$2" --log_file $ephemeris_log 2>&1)
#while [[ $output == *"('Connection aborted.', BadStatusLine("''",))"* ]]; do
#  echo $output
#  if [[ $counter == $COUNT ]]; then break; fi
#  ((counter++))
#  echo "Retry: $counter"
#  sleep 60 # wait for unfinished operations
#  output=$(shed-tools install -g "http://localhost:$PORT" -a $1 -t "$2" 2>&1)
#done

# install tools
shed-tools install -g "http://localhost:$PORT" -a $1 -t "$2" --log_file $ephemeris_log

# define ephemeris success string
ephemeris_success="All repositories have been installed."

# restart ephemeris if the success string is not in the log
counter=0
COUNT=3
while ! grep "$ephemeris_success" $ephemeris_log > /dev/null ; do
  if [[ $counter == $COUNT ]]; then
    echo "Alredy tried $counter times. Exiting. Please check Ephemeris logs at $ephemeris_log."  
    break
  fi
  echo "Not all tools installed. Restarting ephemeris."
  ((counter++))
  echo "Retry: $counter/$COUNT"
  shed-tools install -g "http://localhost:$PORT" -a $1 -t "$2" --log_file $ephemeris_log
done

exit_code=$?
if [ $exit_code != 0 ] ; then
    echo "exiting with code: $exit_code"
    exit $exit_code
fi

# stop Galaxy if it was not running before
if pgrep "supervisord" > /dev/null
then
  echo "Stopping Galaxy"
  sudo -E -u $GALAXY_USER $GALAXY/run.sh --stop $install_pidfile
  # stop postgresql on docker. Keep it running on vm
  if [[ $ID = "ubuntu" ]]; then
    echo "[Ubuntu][Docker] Stop postgresql."
    service stop postgresql
  elif [[ $ID = "centos" ]]; then
    echo "[EL][Docker] Stop postgresql"
    sudo -Hiu postgres /usr/pgsql-${postgresql_version}/bin/pg_ctl -D /var/lib/pgsql/${postgresql_version}/data stop
  fi
fi

# Delete temp galaxy.lite.yml file
rm -f $GALAXY_CONFIG_FILE

# Unset all Galaxy variables
unset GALAXY_CONFIG_FILE
unset GALAXY_CONFIG_DATABASE_CONNECTION
unset GALAXY_CONFIG_DATABASE_CONNECTION_INSTALL
unset GALAXY_CONFIG_TOOL_DEPENDENCY_DIR
unset GALAXY_CONFIG_ADMIN_USERS

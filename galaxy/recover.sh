#!/bin/bash
LOGFILE="/tmp/recover.log"

# Restart cvmfs
sudo systemctl restart autofs > $LOGFILE 2>&1 && sudo /usr/bin/cvmfs_config killall > $LOGFILE 2>&1 && sudo /usr/bin/cvmfs_config probe

# Restart galaxy
sudo /usr/local/bin/galaxy-startup > $LOGFILE 2>&1
/home/galaxy/.laniakea_utils/check_instance

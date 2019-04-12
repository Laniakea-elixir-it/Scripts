#!/bin/bash
LOGFILE="/tmp/recover$(date +"-%b-%d-%y-%H%M%S").log"

# Restart cvmfs
systemctl restart autofs > $LOGFILE 2>&1 && /usr/bin/cvmfs_config killall > $LOGFILE 2>&1 && /usr/bin/cvmfs_config probe

# Restart galaxy
/usr/local/bin/galaxy-startup > $LOGFILE 2>&1
/home/galaxy/.laniakea_utils/check_instance

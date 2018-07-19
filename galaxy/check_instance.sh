#!/bin/bash

OS_STORAGE='IaaS'
URL='http://90.147.170.148/galaxy'
cryptdev_ini_file='/etc/galaxyctl/luks-cryptdev.ini'

_ok='[ OK ]'
_fail='[ FAIL ]'

#____________________________________
# Script needs superuser

function __su_check(){
  if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo -e "[Error] Not running as root."
    exit
 fi
}

#____________________________________
# Check if Galaxy instance by curl
function __galaxy_curl(){
  if curl -s --head  --request GET ${URL} | grep "200 OK" > /dev/null
  then
    return 0
  else
    if curl -s --head  --request GET ${URL} | grep "302 Found" > /dev/null
    then
      return 0
    else
      return 1
    fi
  fi
}

#____________________________________
# Show galaxy status
function __galaxy_url_status(){
  __galaxy_curl &> /dev/null
  code=$?
  if [ $code -eq "0" ]; then 
    echo -e "\nGalaxy server on-line: ${_ok}"
    return 0
  else
    echo -e "\nGalaxy server on-line: ${_fail}"
    echo -e "\nCheking Galaxy server..."
    return 1
  fi
}

#____________________________________
# Check if supervisord is running
function __check_supervisord(){
  if ps ax | grep -v grep | grep supervisord > /dev/null
  then
    return 0
  else
    return 1
  fi
}

#____________________________________
# Check supervisord status
function __supervisord_status(){
  __check_supervisord &> /dev/null
  code=$?
  if [ $code -eq "0" ]; then
    echo -e "\nSupervisord service: ${_ok}"
    return 0
  else
    echo -e "\nSupervisord service: ${_fail}."
    echo -e "\nPlease start Galaxy: sudo galaxy-startup"
    return 1
  fi
}

#____________________________________
# Display supervisorctl status output for Galaxy

function __galaxy_server_status(){
  supervisorctl status galaxy:
  echo -e "\nPlese restart Galaxy using: sudo supervisorctl restart galaxy:"
}

#____________________________________
# Display supervisorctl status output for Galaxy

function __galaxy_status(){
  __check_supervisord
  code=$?  
  if [[ $? == 0 ]]; then
    __galaxy_server_status
  fi
}

cryptdev_ini_file='/tmp/luks-cryptdev.ini'


#____________________________________
# Display dmsetup info

function __dmsetup_info(){
  dmsetup info /dev/mapper/$cryptdev
}

#____________________________________
# check encrypted storage mounted
function __cryptdev_status(){

  # check if $mountpoint is a mount point
  mountpoint $mountpoint &> /dev/null
  if [ $? -ne 0 ]; then
    echo -e "\n${mountpoint} is not a mount point."
    exit 1
  fi

  # if $mountpoint is a mount point 
  __dmsetup_info &>/dev/null

  echo 'LUKS volume configuration'
  echo 'Cipher algorithm:' $cipher_algorithm
  echo 'Hash algorithm:' $hash_algorithm
  echo 'Key size:' $keysize
  echo 'Device:' $device
  echo 'UUID:' $uuid
  echo 'Crypt device:' $cryptdev
  echo 'Mapper:' $mapper
  echo 'Mount point:' $mountpoint
  echo 'File system:' $filesystem

  if [ $? -eq 0 ]; then
    echo -e "\nEncrypted volume: [ OK ]"
  else
    echo -e "\nEncrypted volume: [ FAIL ]"
    echo -e "\nPlease open the encrypted volume with: sudo luksctl open"
  fi
}

#____________________________________
#____________________________________

__galaxy_url_status
code=$?
if [[ $code -ne 0 ]]; then
  __galaxy_status
fi

if [[ $OS_STORAGE == 'encryption' ]]; then
  __cryptdev_status
fi

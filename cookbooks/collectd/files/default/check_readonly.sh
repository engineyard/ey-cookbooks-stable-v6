#!/bin/bash

umask 022

# make tmp dir
status_dir="/tmp/check_readonly_status"
mkdir -p "${status_dir}"

# alert
alert () 
{
  # params
  device="${1}"; severity="${2}"
  timestamp=$(date '+%s')

  # load previous status
  status_file="${status_dir}/device${device//\//-}-status"
  previous_severity=$(cat "${status_file}") 2>/dev/null 

  # send notification
  if [[ $severity != $previous_severity ]]; then
    case "${severity}" in
      OKAY) message="The device mounted at ${device} is writable" ;;
      FAILURE) message="The device mounted at ${device} is read only" ;;
    esac
    
    echo "PUTNOTIF Type=device-status Time=${timestamp} Severity=${severity} Message=\"raw_message: ${message}\""
  fi
  
  # write current status to status file
  echo "${severity}" > "${status_file}"
}

# ignore certain mounts from the check
ignorefile='/etc/engineyard/mounts_ro_ignore'
ignore_mountpoints="$(cat $ignorefile)"
should_ignore_mountpoint ()
{
  local mountpoint="${1}"
  local ignore_code=1
  IFS=$'\n'
  for imp in $ignore_mountpoints; do
    if [[ ! -z "$imp" ]] && [[ "$mountpoint" =~ "$imp" ]]; then
      ignore_code=0
      break
    fi
  done
  return $ignore_code
}

# check for readonly volumes
IFS=$'\n'
for mount_info in $(findmnt --list -n -o TARGET,OPTIONS); do
  IFS=' '
  mount_info=($mount_info)
  mountpoint=${mount_info[0]}
  mount_options=${mount_info[1]}
  if ! should_ignore_mountpoint "$mountpoint"; then
    if [[ "$mount_options" =~ (^|,)ro($|,) ]]; then
      alert "${mountpoint}" "FAILURE"
    else
      alert "${mountpoint}" "OKAY"
    fi
  fi
done

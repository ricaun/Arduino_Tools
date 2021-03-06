#!/bin/bash

set -e

if [ $# -lt 4 ]; then
  echo "Usage: $0 $# <dummy_port> <altID> <usbID> <binfile>" >&2
  exit 1
fi
altID=$2
usbID=$3
binfile=$4
dummy_port_fullpath="/dev/$1"

# Get the directory where the script is running.
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# -----------------  Old code to reset the USB - which doesn't seem to work --------
#
#if we can find the Serial device try resetting it and then sleeping for 1 sec while the board reboots
#if [ -e $dummy_port_fullpath ]; then
#	echo "resetting " $dummy_port_fullpath
#	stty -f $dummy_port_fullpath 1200
#	sleep 1
##	stty -f $dummy_port_fullpath 1200
##	sleep 1
#fi
# ------------------  End of old code -----------------

#  ----------------- IMPORTANT -----------------
# The 2nd parameter to upload-reset is the delay after resetting before it exits
# This value is in milliseonds
# You may need to tune this to your system
# 750ms to 1500ms seems to work on my Mac

"${DIR}"/upload-reset "${dummy_port_fullpath}" 750

if [ $# -eq 5 ]; then
  dfuse_addr="--dfuse-address $5"
else
  dfuse_addr=""
fi

#DFU_UTIL=/usr/local/bin/dfu-util
DFU_UTIL=${DIR}/dfu-util/dfu-util
if [ ! -x "${DFU_UTIL}" ]; then
  DFU_UTIL=/opt/local/bin/dfu-util
fi

if [ ! -x ${DFU_UTIL} ]; then
  echo "$0: error: cannot find ${DFU_UTIL}" >&2
  exit 2
fi

${DFU_UTIL} -d "${usbID}" -a "${altID}" -D "${binfile}" -R ${dfuse_addr} -R

echo -n Waiting for "${dummy_port_fullpath}" serial...

COUNTER=0
while [ ! -c "${dummy_port_fullpath}" ] && ((COUNTER++ < 40)); do
  sleep 0.1
done

echo Done

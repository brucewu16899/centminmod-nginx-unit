#!/bin/bash
######################################################
# nginx unit json merge script where json configs are
# saved at /root/tools/unitconfigs with .json extension
# written by George Liu (eva2000) centminmod.com
######################################################
# variables
#############
DT=$(date +"%d%m%y-%H%M%S")

JSONCONFIGS=$(find /root/tools/unitconfigs -type f -name "*.json" -exec basename {} \; | tr '\n' ' ')
JSCONFIGS_COUNT=$(find /root/tools/unitconfigs -type f -name "*.json" -exec basename {} \; |wc -l)
######################################################
# functions
#############
if [ ! -f /usr/bin/jq ]; then
  yum -y -q install jq
fi

json_merge() {
  count=$(($JSCONFIGS_COUNT-1))
  echo -n 'jq -s '
  echo -n "'.[0]"
  for (( i=1; i<=$count; i++ )); do
    echo -n " * .[$i]"
  done
  echo -n "'"
  echo -n " $JSONCONFIGS"
  echo -n ' | curl -X PUT -d@-  http://localhost'
  echo
}

######################################################


case "$1" in
  merge-json )
    json_merge
    ;;
  * )
    echo
    echo "$0 {merge-json}"
    ;;
esac
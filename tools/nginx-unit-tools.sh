#!/bin/bash
######################################################
# nginx unit json merge script where json configs are
# saved at /root/tools/unitconfigs with .json extension
# written by George Liu (eva2000) centminmod.com
######################################################
# variables
#############
DT=$(date +"%d%m%y-%H%M%S")

MULTI_PHPVER='n'
######################################################
mkdir -p /root/tools/unitconfigs
JSONCONFIGS=$(find /root/tools/unitconfigs -type f -name "*.json" -exec basename {} \; | tr '\n' ' ')
JSCONFIGS_COUNT=$(find /root/tools/unitconfigs -type f -name "*.json" -exec basename {} \; |wc -l)
######################################################
# functions
#############
if [ -f /proc/user_beancounters ]; then
    # CPUS='1'
    # MAKETHREADS=" -j$CPUS"
    # speed up make
    CPUS=$(grep -c "processor" /proc/cpuinfo)
    if [[ "$CPUS" -gt '8' ]]; then
        CPUS=$(echo $(($CPUS+2)))
    else
        CPUS=$(echo $(($CPUS+1)))
    fi
    MAKETHREADS=" -j$CPUS"
else
    # speed up make
    CPUS=$(grep -c "processor" /proc/cpuinfo)
    if [[ "$CPUS" -gt '8' ]]; then
        CPUS=$(echo $(($CPUS+4)))
    elif [[ "$CPUS" -eq '8' ]]; then
        CPUS=$(echo $(($CPUS+2)))
    else
        CPUS=$(echo $(($CPUS+1)))
    fi
    MAKETHREADS=" -j$CPUS"
fi

if [ ! -d /usr/local/src/centminmod ]; then
  echo
  echo "Centmin Mod LEMP Stack not found"
  exit
fi

if [ ! -f /usr/bin/jq ]; then
  yum -y -q install jq
fi

unit_install() {
  if [ "$(php-config --php-sapis | grep embed)" ]; then
    echo
    echo "Installing Nginx Unit ..."
    # GCC 6.3.1 required for remi php 7.2 compatibility
    if [ -f /usr/local/src/centminmod/addons/devtoolset-6.sh ]; then
      /usr/local/src/centminmod/addons/devtoolset-6.sh
    fi
    if [ ! -f /usr/bin/python-config ]; then
      yum -y install python-devel
    fi
    if [ ! -f /usr/local/go/bin/go ]; then
      /usr/local/src/centminmod/addons/golang.sh install
      source /root/.bashrc
    fi
    if [[ "$MULTI_PHPVER" = [yY] ]]; then
      cd /root/tools
      if [ ! -d /root/tools/centminmod-php71/.git ]; then
        git clone https://github.com/centminmod/centminmod-php71
        cd centminmod-php71
      elif [ -d /root/tools/centminmod-php71/.git ]; then
        git pull
        cd centminmod-php71
      fi
      ./php56.sh install
      ./php70.sh install
      ./php71.sh install
      ./php72.sh install
    fi
    export CC="gcc"
    export CXX="g++"
    if [ -f /opt/rh/devtoolset-6/root/usr/bin/gcc ]; then
      source /opt/rh/devtoolset-6/enable
    fi
    cd /svr-setup
    if [ ! -d /svr-setup/unit/.git ]; then
      git clone https://github.com/nginx/unit
      cd unit
    elif [ -d /svr-setup/unit/.git ]; then
      git pull
      cd unit
    fi
    make clean >/dev/null 2>&1
    ./configure --prefix=/opt/unit --pid=/run/unitd.pid --log=/var/log/unitd.log --modules=modules --user=nginx --group=nginx --state=state
    ./configure go
    ./configure python
    phpver=$(php -v | head -n1 | awk '{print tolower($2)}')
    ./configure php --module="php${phpver}" --config=/usr/local/bin/php-config --lib-path=/usr/local/lib
    if [[ "$MULTI_PHPVER" = [yY] ]]; then
      ./configure php --module=remiphp56 --config=/opt/remi/php56/root/usr/bin/php-config --lib-path=/opt/remi/php56/root/usr/lib64
      ./configure php --module=remiphp70 --config=/opt/remi/php70/root/usr/bin/php-config --lib-path=/opt/remi/php70/root/usr/lib64
      ./configure php --module=remiphp71 --config=/opt/remi/php71/root/usr/bin/php-config --lib-path=/opt/remi/php71/root/usr/lib64
      ./configure php --module=remiphp72 --config=/opt/remi/php72/root/usr/bin/php-config --lib-path=/opt/remi/php72/root/usr/lib64
    fi
    make${MAKETHREADS} all
    make install
    mkdir -p /root/tools/unitconfigs /opt/unit/state
    mkdir -p /etc/systemd/system/unitd.service.d
    echo -en "[Service]\nLimitNOFILE=262144\nLimitNPROC=16384\n" > /etc/systemd/system/unitd.service.d/limit.conf
    wget -O /usr/lib/systemd/system/unitd.service https://github.com/centminmod/centminmod-nginx-unit/raw/master/systemd/unitd.service
    systemctl daemon-reload
    systemctl start unitd
    echo
    systemctl status unitd
    echo
    /opt/unit/sbin/unitd --version
    echo
    echo "Nginx Unit installed"
  else
    echo
    echo "php embed SAPI libarary not installed"
    echo "update Centmin Mod 123.09beta01 to latest code"
    echo "via centmin.sh menu option 23 submenu option 2"
    echo "then recompile PHP version via centmin.sh menu"
    echo "option 5"
    exit
  fi
}

json_merge() {
  count=$(($JSCONFIGS_COUNT-1))
  echo -n 'jq -s '
  echo -n "'.[0]"
  for (( i=1; i<=$count; i++ )); do
    echo -n " * .[$i]"
  done
  echo -n "'"
  echo -n " $JSONCONFIGS"
  echo -n ' | curl -X PUT -d@- --unix-socket /opt/unit/control.unit.sock http://localhost'
  echo
}

######################################################


case "$1" in
  install-unit)
    unit_install
    ;;
  merge-json )
    json_merge
    ;;
  * )
    echo
    echo "$0 {install-unit|merge-json}"
    ;;
esac
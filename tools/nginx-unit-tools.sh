#!/bin/bash
######################################################
# nginx unit json merge script where json configs are
# saved at /root/tools/unitconfigs with .json extension
# written by George Liu (eva2000) centminmod.com
######################################################
# variables
#############
DT=$(date +"%d%m%y-%H%M%S")
UNIT_VERSION='1.0'
UNIT_DEBUG='y'

MULTI_PHPVER='y'
PYTHONTHREEFOUR='y'
PYTHONTHREEFIVE='y'
PYTHONTHREESIX='y'
PERLFIVEONE='y'
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

if [[ "$UNIT_DEBUG" = [yY] ]]; then
  DEBUGLOG=' --debug'
else
  DEBUGLOG=""
fi

if [ ! -d /usr/local/src/centminmod ]; then
  echo
  echo "Centmin Mod LEMP Stack not found"
  exit
fi

if [ ! -f /usr/bin/jq ]; then
  yum -y -q install jq
fi

if [ ! -f /usr/include/ruby.h ]; then
  yum -y -q install ruby-devel
fi

if [ ! -f /usr/include/ffi.h ]; then
  yum -y -q install libffi-devel
fi

if [ ! -f /usr/include/sqlite3.h ]; then
  yum -y -q install sqlite-devel
fi

if [ ! -f /usr/include/yaml.h ]; then
  yum -y -q install libyaml-devel
fi

unit_install() {
  if [ "$(php-config --php-sapis | grep embed)" ]; then
    echo
    echo "Installing Nginx Unit ..."
    # GCC 6.3.1 required for remi php 7.2 compatibility
    if [[ ! -f /opt/rh/devtoolset-6/root/usr/bin/gcc && -f /usr/local/src/centminmod/addons/devtoolset-6.sh ]]; then
      /usr/local/src/centminmod/addons/devtoolset-6.sh
    fi
    if [ ! -f /usr/bin/python-config ]; then
      yum -y install python-devel
    fi
    if [ ! -f /usr/local/go/bin/go ]; then
      /usr/local/src/centminmod/addons/golang.sh install
      source /root/.bashrc
    fi
    if [[ "$PYTHONTHREEFOUR" = [yY] && -f /usr/local/src/centminmod/addons/python34_install.sh && ! -f /usr/bin/python3.4-config ]]; then
      /usr/local/src/centminmod/addons/python34_install.sh
    fi
    if [[ "$PYTHONTHREEFIVE" = [yY] && -f /usr/local/src/centminmod/addons/python35_install.sh && ! -f /usr/bin/python3.5-config ]]; then
      /usr/local/src/centminmod/addons/python35_install.sh
    fi
    if [[ "$PYTHONTHREESIX" = [yY] && -f /usr/local/src/centminmod/addons/python36_install.sh && ! -f /usr/bin/python3.6-config ]]; then
      /usr/local/src/centminmod/addons/python36_install.sh
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
      if [ ! -f /opt/remi/php56/root/etc/php-fpm.d/www.conf ]; then
        ./php56.sh install
      fi
      if [ ! -f /etc/opt/remi/php70/php-fpm.d/www.conf ]; then
        ./php70.sh install
      fi
      if [ ! -f /etc/opt/remi/php71/php-fpm.d/www.conf ]; then
        ./php71.sh install
      fi
      if [ ! -f /etc/opt/remi/php72/php-fpm.d/www.conf ]; then
        ./php72.sh install
      fi
    fi
    export CC="gcc"
    export CXX="g++"
    if [ -f /opt/rh/devtoolset-6/root/usr/bin/gcc ]; then
      source /opt/rh/devtoolset-6/enable
    fi
    if [ -f /opt/rh/devtoolset-7/root/usr/bin/gcc ]; then
      source /opt/rh/devtoolset-7/enable
    fi
    cd /svr-setup
    rm -rf unit
    git clone https://github.com/nginx/unit
    cd unit
    git checkout ${UNIT_VERSION} -b ${UNIT_VERSION}
    make clean >/dev/null 2>&1
    ./configure --prefix=/opt/unit --pid=/run/unitd.pid --log=/var/log/unitd.log --modules=modules --user=nginx --group=nginx --state=state${DEBUGLOG} \
    --cc-opt='-O3 -fstack-protector-strong -fuse-ld=gold -Wimplicit-fallthrough=0 -fcode-hoisting'
    ./configure go
    if [[ "$PERLFIVEONE" = [yY] ]]; then
      ./configure perl --module=perl516 --perl=perl5.16.3
    fi
    ./configure python --module=python27 --config=python2.7-config
    phpver=$(php -v | head -n1 | awk '{print tolower($2)}' | sed -e 's|\.||g')
    ./configure php --module="php${phpver}" --config=/usr/local/bin/php-config --lib-path=/usr/local/lib
    if [[ "$MULTI_PHPVER" = [yY] ]]; then
      ./configure php --module=remiphp56 --config=/opt/remi/php56/root/usr/bin/php-config --lib-path=/opt/remi/php56/root/usr/lib64
      ./configure php --module=remiphp70 --config=/opt/remi/php70/root/usr/bin/php-config --lib-path=/opt/remi/php70/root/usr/lib64
      ./configure php --module=remiphp71 --config=/opt/remi/php71/root/usr/bin/php-config --lib-path=/opt/remi/php71/root/usr/lib64
      ./configure php --module=remiphp72 --config=/opt/remi/php72/root/usr/bin/php-config --lib-path=/opt/remi/php72/root/usr/lib64
    fi
    if [[ "$PYTHONTHREEFOUR" = [yY] && -f /usr/bin/python3.4-config ]]; then
      ./configure python --module=iuspython34 --config=/usr/bin/python3.4-config
    fi
    if [[ "$PYTHONTHREEFIVE" = [yY] && -f /usr/bin/python3.5-config ]]; then
      ./configure python --module=iuspython35 --config=/usr/bin/python3.5-config
    fi
    if [[ "$PYTHONTHREESIX" = [yY] && -f /usr/bin/python3.6-config ]]; then
      ./configure python --module=iuspython36 --config=/usr/bin/python3.6-config
    fi
    make${MAKETHREADS} all
    make install
    mkdir -p /root/tools/unitconfigs /opt/unit/state
    mkdir -p /etc/systemd/system/unitd.service.d
    echo -en "[Service]\nLimitNOFILE=524288\nLimitNPROC=65536\n" > /etc/systemd/system/unitd.service.d/limit.conf
    wget -O /usr/lib/systemd/system/unitd.service https://github.com/centminmod/centminmod-nginx-unit/raw/master/systemd/unitd.service
    systemctl daemon-reload
    systemctl start unitd
    systemctl enable unitd
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
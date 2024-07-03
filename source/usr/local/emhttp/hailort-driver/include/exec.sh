#!/bin/bash

function update(){
KERNEL_V="$(uname -r)"
PACKAGE="hailort_driver"
CURENTTIME=$(date +%s)
CHK_TIMEOUT=300
if [ -f /tmp/hailort_driver ]; then
  FILETIME=$(stat /tmp/hailort_driver -c %Y)
  DIFF=$(expr $CURENTTIME - $FILETIME)
  if [ $DIFF -gt $CHK_TIMEOUT ]; then
    wget -qO- https://api.github.com/repos/ich777/unraid-hailort-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep -E -v '\.md5$' | sort -V | cut -d '-' -f2 | tail -10 > /tmp/hailort_driver
    if [ ! -s /tmp/hailort_driver ]; then
      echo -n "$(modinfo hailo_pci | grep -w "version:" | awk '{print $2}' | head -1)" > /tmp/hailort_driver
    fi
  fi
else
  wget -qO- https://api.github.com/repos/ich777/unraid-hailort-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep -E -v '\.md5$' | sort -V | cut -d '-' -f2 | tail -10  > /tmp/hailort_driver
  if [ ! -s /tmp/hailort_driver ]; then
    echo -n "$(modinfo hailo_pci | grep -w "version:" | awk '{print $2}' | head -1)" > /tmp/hailort_driver
  fi
fi
}

function update_version(){
sed -i "/driver_version=/c\driver_version=${1}" "/boot/config/plugins/hailort-driver/settings.cfg"
/usr/local/emhttp/plugins/hailort-driver/include/download.sh
}

function get_latest_version(){
KERNEL_V="$(uname -r)"
echo -n "$(cat /tmp/hailort_driver | sort -V | tail -1)"
}

function get_selected_version(){
echo -n "$(cat /boot/config/plugins/hailort-driver/settings.cfg | grep "driver_version" | cut -d '=' -f2 | sed 's/\"//g')"
}

function get_installed_version(){
echo -n "$(modinfo hailo_pci | grep -w "version:" | awk '{print $2}' | head -1)"
}

$@

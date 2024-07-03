#!/bin/bash
#Get versions
DRIVER_VERSION="$(cat /boot/config/plugins/hailort-driver/settings.cfg | grep "driver_version" | cut -d '=' -f2 | sed 's/\"//g')"
AVAIL_VERSIONS="$(cat /tmp/hailort_driver)"

#Determin driver version to download
if [ "${DRIVER_VERSION}" == "latest" ]; then
  DRV_V="$(cat /tmp/hailort_driver | sort -V | tail -1)"
else
  DRV_V="${DRIVER_VERSION}"
fi
KERNEL_V="$(uname -r)"
PACKAGE="hailort_driver"
DL_URL="https://github.com/ich777/unraid-hailort-driver/releases/download/${KERNEL_V}"
PACKAGE="${PACKAGE}-${DRV_V}-${KERNEL_V}-1.txz"

download() {
if wget -q -nc --show-progress --progress=bar:force:noscroll -O "/boot/config/plugins/hailort-driver/packages/${KERNEL_V%%-*}/${PACKAGE}" "${DL_URL}/${PACKAGE}" ; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O "/boot/config/plugins/hailort-driver/packages/${KERNEL_V%%-*}/${PACKAGE}.md5" "${DL_URL}/${PACKAGE}.md5"
  if [ "$(md5sum /boot/config/plugins/hailort-driver/packages/${KERNEL_V%%-*}/${PACKAGE} | awk '{print $1}')" != "$(cat /boot/config/plugins/hailort-driver/packages/${KERNEL_V%%-*}/${PACKAGE}.md5 | awk '{print $1}')" ]; then
    echo
    echo "----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR----"
    echo "-------------------------------CHECKSUM ERROR!-------------------------------"
    rm -rf /boot/config/plugins/hailort-driver/packages/${KERNEL_V%%-*}/${PACKAGE}*
    exit 1
  fi
  echo
  echo "----------Successfully downloaded Hailo RT Driver Package v${DRV_V}----------"
else
  echo
  echo "---------------Can't download Hailo RT Driver Package v${DRV_V}---------------"
  exit 1
fi
}

notify() {
echo
echo "----To install the Hailo RT Driver v${DRV_V} please reboot your Server!----"
/usr/local/emhttp/plugins/dynamix/scripts/notify -e "Hailo RT Driver" -d "To install the Hailo RT Driver v${DRV_V} please reboot your Server!" -i "alert" -l "/Main"
#Remove old packages
rm -f $(ls -1 /boot/config/plugins/hailort-driver/packages/${KERNEL_V%%-*}/* 2>/dev/null | grep -v "${DRV_V}")
}

if ls /boot/config/plugins/hailort-driver/packages/${KERNEL_V%%-*}/ | grep -v ".md5" | grep -q "${DRV_V}" ; then
  echo
  echo "---Already found Hailo RT Driver package v${DRV_V}, trying to redownload...---"
  rm -f /boot/config/plugins/hailort-driver/packages/${KERNEL_V%%-*}/${PACKAGE}*
  download
  notify
else
  echo
  echo "--------Downloading Hailo RT Driver package v${DRV_V}, please wait...--------"
  download
  notify
fi

$@  

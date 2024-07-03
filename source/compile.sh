#Define function
hailort_driver() {
  if [ -d /HAILORT ]; then
    rm -rf /HAILORT
  fi
  mkdir -p /HAILORT/lib/firmware/hailo /HAILORT/lib/modules/${UNAME}/kernel/drivers/misc/
  cd ${DATA_DIR}
  if [ ! -d ${DATA_DIR}/hailort-drivers ]; then
    git clone https://github.com/hailo-ai/hailort-drivers
  fi
  cd ${DATA_DIR}/hailort-drivers
  git checkout v${1}

  # Compile module and copy it over to destination
  cd ${DATA_DIR}/hailort-drivers/linux/pcie
  make all -j${CPU_COUNT}
  cp ${DATA_DIR}/hailort-drivers/linux/pcie/hailo_pci.ko /HAILORT/lib/modules/${UNAME}/kernel/drivers/misc/hailo_pci.ko

  #Compress module
  while read -r line
  do
    xz --check=crc32 --lzma2 $line
  done < <(find /HAILORT/lib/modules/${UNAME}/kernel/drivers/misc -name "*.ko")

  # Download Firmware
  cd /HAILORT/lib/firmware/hailo
  chmod +x ${DATA_DIR}/hailort-drivers/download_firmware.sh
  ${DATA_DIR}/hailort-drivers/download_firmware.sh
  mv /HAILORT/lib/firmware/hailo/hailo8_fw*.bin /HAILORT/lib/firmware/hailo/hailo8_fw.bin

  # Create Slackware Package
  PLUGIN_NAME="hailort_driver"
  BASE_DIR="/HAILORT"
  TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
  VERSION="$(date +'%Y.%m.%d')"
  mkdir -p $TMP_DIR/$VERSION
  cd $TMP_DIR/$VERSION
  cp -R $BASE_DIR/* $TMP_DIR/$VERSION/
  mkdir $TMP_DIR/$VERSION/install
  tee $TMP_DIR/$VERSION/install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: $PLUGIN_NAME v${1} Package contents:
$PLUGIN_NAME:
$PLUGIN_NAME: Source: https://github.com/hailo-ai/hailort-drivers
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME package for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
  ${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n $TMP_DIR/$PLUGIN_NAME-${1}-$UNAME-1.txz
  md5sum $TMP_DIR/$PLUGIN_NAME-${1}-$UNAME-1.txz | awk '{print $1}' > $TMP_DIR/$PLUGIN_NAME-${1}-$UNAME-1.txz.md5
}

#Get latest 3 tags from GitHub
HAILO_TAGS="$(curl -u $GITHUB_USER:$GITHUB_SECRET -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/hailo-ai/hailort-drivers/tags | jq -r '.[].name' | cut -d 'v' -f2 | sort -V | tail -3)"

#Loop through tags and create packages
IFS=$'\n'
for hailo_tag in $HAILO_TAGS; do
  hailort_driver "$hailo_tag"
done

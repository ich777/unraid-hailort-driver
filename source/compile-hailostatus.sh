#!/bin/bash
## https://github.com/ssttevee/zig-hailo
DATA_DIR=/root/hailo
CPU_COUNT=20
ZIGPATH=${DATA_DIR}/zig-linux-x86_64-0.14.0-dev.208+854e86c56

cd ${DATA_DIR}
git clone https://github.com/ssttevee/zig-hailo
cd ${DATA_DIR}/zig-hailo
git checkout trunk
${ZIGPATH}/zig build -Dcpu=x86_64 -Doptimize=ReleaseSafe

VERSION="$(date +'%Y-%m-%d')"
mkdir -p ${DATA_DIR}/${VERSION}
cp ${DATA_DIR}/zig-hailo/zig-out/bin/hailostatus ${DATA_DIR}/${VERSION}/

cd ${DATA_DIR}/${VERSION}
md5sum hailostatus | awk '{print $1}' > hailostatus.md5

## Cleanup
rm -R ${DATA_DIR}/zig-hailo

## Upload
cd ${DATA_DIR} 
exit 0
#!/system/bin/sh
if ! applypatch -c EMMC:/dev/block/mmcblk0p13:5976320:9c2b34e493348da6244ce9207c1865ad411f31b0; then
  log -t recovery "Installing new recovery image"
  applypatch EMMC:/dev/block/mmcblk0p8:5259520:387994841f703e4a37c04dd9a8eaea04d27c70b3 EMMC:/dev/block/mmcblk0p13 9c2b34e493348da6244ce9207c1865ad411f31b0 5976320 387994841f703e4a37c04dd9a8eaea04d27c70b3:/system/recovery-from-boot.p
else
  log -t recovery "Recovery image already installed"
fi

if [ -e /cache/recovery/command ] ; then
  rm /cache/recovery/command
fi

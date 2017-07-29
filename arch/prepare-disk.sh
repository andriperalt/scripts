#!/bin/bash
set -e
>prepare-disk.log
>prepare-disk.err
exec > >(tee -ia prepare-disk.log) 2> >(tee -ia prepare-disk.err >&2)

disk_name=$1

if test -n "$disk_name"; then
  printf "\n\n======= PLEASE MAKE SURE TO ERASE AND UNMOUNT DISK /dev/${disk_name} FIRST ======\n\n"
  
  cryptsetup open --type plain "/dev/${disk_name}" cryptdisk --key-file /dev/random && echo "Mount disk /dev/${disk_name} with random encrypt"  
  
  dd if=/dev/zero of=/dev/mapper/cryptdisk status=progress bs=1M && echo "Wipe /dev/${disk_name}"
  
  cryptsetup close cryptdisk && echo "Close the temporary container"
else
  echo "Define disk name. Run lsblk -f to know the name of the disks" >&2
fi

exit 0

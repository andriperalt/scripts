#!/bin/bash
>prepare-disk.log
>prepare-disk.err
exec > >(tee -ia prepare-disk.log) 2> >(tee -ia prepare-disk.err >&2)

disk_name=$1

function mount_cryptdisk {
  cryptsetup open --type plain "/dev/${disk_name}" cryptdisk --key-file /dev/random
}

function wipe_cryptdisk {
  dd if=/dev/zero of=/dev/mapper/cryptdisk status=progress bs=1M
}

function close_cryptdisk {
  cryptsetup close cryptdisk
  echo "Close the temporary container"
}

if test -n "$disk_name" ; then
  echo "======= PLEASE MAKE SURE TO ERASE AND UNMOUNT DISK /dev/${disk_name} FIRST ======\n\n"
  
  if mount_cryptdisk ; then
    echo "Mount disk /dev/${disk_name} with random encrypt"
    if wipe_cryptdisk ; then
      echo "Wipe /dev/${disk_name}"
      close_cryptdisk
    else
      close_cryptdisk
      exit
    fi
  else
    exit
  fi
else
  echo "Please define disk name. Run lsblk -f to know the name of the disks"
fi

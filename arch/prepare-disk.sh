#!/bin/bash
>prepare-disk.log
>prepare-disk.err
exec > >(tee -ia prepare-disk.log) 2> >(tee -ia prepare-disk.err >&2)

disk_name=$1

function mount_cryptdisk {
  cryptsetup open --type plain "/dev/${disk_name}" cryptdisk --key-file /dev/random
}

function wipe_cryptdisk {
  dd if=/dev/zero of=/dev/mapper/cryptdisk status=progress bs=1M
}

function close_cryptdisk {
  cryptsetup close cryptdisk
}

if test -n "$disk_name" ; then
  echo "======= PLEASE MAKE SURE TO ERASE AND UNMOUNT DISK /dev/${disk_name} FIRST ======"
  
  if mount_cryptdisk ; then
    echo "====== OK: Mount disk /dev/${disk_name} with random encrypt ======="
    if wipe_cryptdisk ; then
      echo "====== OK: Wipe /dev/${disk_name} ====== "
      if close_cryptdisk ; then
        echo "====== OK: Close the temporary container ======"
      else
        exit 1
      fi
    else
      if close_cryptdisk ; then
        echo "====== OK: Close the temporary container ======"
      else 
        exit 1
      fi
      exit 1
    fi
  else
    exit 1
  fi
else
  echo "====== ERROR: Please define disk name. Run lsblk -f to know the name of the disks ======"
fi

exit 0

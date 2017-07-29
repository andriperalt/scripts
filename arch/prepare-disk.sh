#! /bin/sh

disk_name=$1

>prepare-disk.log
>prepare-disk.err
exec >  >(tee -ia prepare-disk.log)
exec 2> >(tee -ia prepare-disk.err >&2)

if test -n "$disk_name"; then
  printf "\n\n======= PLEASE MAKE SURE TO ERASE AND UNMOUNT DISK /dev/${disk_name} FIRST ======\n\n"

  printf "\n\nMount disk /dev/${disk_name} with random encrypt\n\n"
  cryptsetup open --type plain "/dev/${disk_name}" cryptdisk --key-file /dev/random

  printf "\n\nWipe /dev/${disk_name}\n\n"
  dd if=/dev/zero of=/dev/mapper/cryptdisk status=progress bs=1M

  printf "\n\nClose the temporary container\n\n"
  cryptsetup close cryptdisk
else
  printf "\n\nDefine disk name. Run lsblk -f to know the name of the disks\n\n"
fi


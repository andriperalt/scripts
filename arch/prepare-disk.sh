#! /bin/sh

#run lsblk -f to know the name of the disk 
disk_name=$1

if test -n "$disk_name"; then
  printf "\n\n======= PLEASE MAKE SURE TO ERASE DISK FIRST ======\n\n"

  printf "\n\nMount disk with random encrypt -> disk sda\n\n"
  cryptsetup open --type plain "${disk_name}" cryptdisk --key-file /dev/random

  printf "\n\nWipe disk\n\n"
  dd if=/dev/zero of=/dev/mapper/cryptdisk status=progress bs=1M

  printf "\n\nClose the temporary container\n\n"
  cryptsetup close cryptdisk
else
  printf "\n\nDefine disk name\n\n"
fi

#! /bin/sh

#name like /dev/sda
disk_name=$1

printf "\n\n======= PLEASE MAKE SURE TO ERASE DISK FIRST ======\n\n"

printf "\n\nMount disk with random encrypt -> disk sda\n\n"
cryptsetup open --type plain "${disk_name}" cryptdisk --key-file /dev/random

printf "\n\nWipe disk\n\n"
dd if=/dev/zero of=/dev/mapper/cryptdisk status=progress bs=1M

printf "\n\nClose the temporary container\n\n"
cryptsetup close cryptdisk

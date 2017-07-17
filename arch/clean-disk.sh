#! /bin/sh

printf "\n\nMount disk with random encrypt -> disk sda\n\n"
cryptsetup open --type plain /dev/sda cryptdisk --key-file /dev/random

printf "\n\nWipe disk\n\n"
dd if=/dev/zero of=/dev/mapper/cryptdisk status=progress bs=1M

printf "\n\nClose the temporary container\n\n"
cryptsetup close cryptroot

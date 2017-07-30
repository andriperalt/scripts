#!/bin/bash
# Fail if variables unset
set -o nounset
# Fail if any error
set -o errexit

# Prepare logs
>prepare-disk.log
>prepare-disk.err
exec > >(tee -ia prepare-disk.log) 2> >(tee -ia prepare-disk.err >&2)

# Define variables
disk_name=$1
mapped_name=cryptdisk

function close_mapped_disk {
  cryptsetup close "${mapped_name}" && echo "====== OK: Close the temporary container ======"
}

echo "====== INFO: To define disk name run lsblk -f to know the name of the disks ======"

echo "====== INFO: PLEASE MAKE SURE TO ERASE AND UNMOUNT DISK /dev/${disk_name} FIRST ======"

if cryptsetup open --type plain "/dev/${disk_name}" "${mapped_name}" --key-file /dev/random && echo "====== OK: Mount disk /dev/${disk_name} with random encrypt ======="
then
  trap close_mapped_disk INT TERM EXIT
  dd if=/dev/zero of="/dev/mapper/${mapped_name}" status=progress bs=1M && echo "====== OK: Wipe /dev/${disk_name} ======"
  trap - INT TERM EXIT
fi

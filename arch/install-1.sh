#!/bin/bash

# Prepare logs
>install-1.log
>install-1.err
exec > >(tee -ia install-1.log) 2> >(tee -ia install-1.err >&2)

# Variables
disk_name=$1
boot=$2
swap=$3
root=$4
keyboard_layout=$5
wifi=$6
mapped_swap=cryptswap
mapped_root=cryptroot

echo "====== INFO: Unmounting all ======"
umount -R /mnt
cryptsetup close "${mapped_root}"
echo ""

# Fail if variables unset
set -o nounset
# Fail if any error
set -o errexit

{
  gdisk "/dev/${disk_name}" \
  && echo "====== INFO: Disk /dev/${disk_name} formatted" \
  && echo ""
} && {
  lsblk -f \
  && echo "====== INFO: Printed partitions and mounts ======" \
  && echo ""
} && {
  loadkeys "${keyboard_layout}" \
  && echo "====== INFO: Setted keyboard layout to ${keyboard_layout} ======" \
  && echo ""
} && {
  if [ "${wifi}" == "true" ]
  then
    wifi-menu \
    && echo "====== INFO: Setted wifi ======" \
    && echo ""
  else
    systemctl restart dhcpcd.service \
    && echo "====== INFO: Setted dhcp ======" \
    && echo ""
  fi
} && {
  timedatectl set-ntp true \
  && echo "====== INFO: Updated the system clock, enable NTP ======" \
  && echo ""
} && {
  timedatectl status \
  && echo "====== INFO: Printed clock status ======" \
  && echo ""
} && {
  mkfs.fat -F32 -n BOOT "/dev/${boot}" \
  && echo "====== INFO: Formated boot/efi on partition /dev/${boot} ======" \
  && echo ""
} && {
  mkfs.ext2 -L "${mapped_swap}" "/dev/${swap}" 1M \
  && echo "====== INFO: Formated swap on partition /dev/${swap} ======" \
  && echo ""
} && {
  cryptsetup luksFormat --key-size 512 "/dev/${root}" \
  && echo "====== INFO: Created LUKS root container -> partition /dev/${root} ======" \
  && echo ""
} && {
  cryptsetup open --type luks "/dev/${root}" "${mapped_root}" \
  && echo "====== INFO: Unlocked LUKS root container ======" \
  && echo ""
} && {
  mkfs.btrfs -L "${mapped_root}" "/dev/mapper/${mapped_root}" \
  && echo "====== INFO: Formated mapped device /dev/mapper/${mapped_root} =======" \
  && echo ""
} && {
  mount --options compress=lzo "/dev/mapper/${mapped_root}" /mnt/ \
  && echo "====== INFO: Mounted mapped /dev/mapper/${mapped_root} ======" \
  && echo ""
} && {
  btrfs subvolume create /mnt/@ \
  && btrfs subvolume create /mnt/@snapshots \
  && btrfs subvolume create /mnt/@home \
  && echo "====== INFO: Create top-level subvolumes ======" \
  && echo ""
} && {
  umount /mnt \
  && echo "====== INFO: Unmount the system partition ======" \
  && echo ""
} && {
  mount --options compress=lzo,subvol=@ "/dev/mapper/${mapped_root}" /mnt \
  && mkdir /mnt/home \
  && mount --options compress=lzo,subvol=@home "/dev/mapper/${mapped_root}" /mnt/home \
  && mkdir /mnt/.snapshots \
  && mount --options compress=lzo,subvol=@snapshots "/dev/mapper/${mapped_root}" /mnt/.snapshots \
  && echo "====== INFO: Mounted top-level subvolumes ======" \
  && echo ""
} && {
  mkdir -p /mnt/var/cache/pacman \
  && btrfs subvolume create /mnt/var/cache/pacman/pkg \
  && btrfs subvolume create /mnt/var/abs \
  && btrfs subvolume create /mnt/var/tmp \
  && btrfs subvolume create /mnt/srv \
  && echo "====== INFO: Create nested sub-volume ======" \
  && echo ""
} && {
  mkdir /mnt/boot \
  && mount "/dev/${boot}" /mnt/boot \
  && echo "====== INFO: Mounted boot/ESP to /dev/${boot} ======" \
  && echo ""
} && {
  pacstrap /mnt base \
  && echo "====== INFO: Installed the base package ======" \
  && echo ""
} && {
  genfstab -U /mnt >> /mnt/etc/fstab \
  && echo "/dev/mapper/swap	none	swap	defaults	0	0" >> /mnt/etc/fstab \
  && echo "swap	LABEL=cryptswap	/dev/urandom	swap,offset=2048,cipher=aes-xts-plain64,size=256" >> /mnt/etc/crypttab \
  && cat /mnt/etc/fstab \
  && cat  /mnt/etc/crypttab \
  && echo "====== INFO: Executed fstab ======" \
  && echo "====== INFO: Finished, please execute: arch-chroot /mnt ======"
}

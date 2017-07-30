#!/bin/bash

# Fail if variables unset
set -o nounset
# Fail if any error
set -o errexit

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

gdisk "/dev/${disk_name}" && echo "====== INFO: Disk /dev/${disk_name} formatted"
echo ""

lsblk -fl && echo "====== INFO: Printed partitions and mounts ======"
echo ""

loadkeys "${keyboard_layout}" && echo "====== INFO: Setted keyboard layout to ${keyboard_layout} ======"
echo ""

if test -n "${wifi}"
then
  wifi-menu && echo "======= INFO: Setted wifi ======"
  echo ""
fi

timedatectl set-ntp true && echo "====== INFO: Updated the system clock, enable NTP ======"
echo ""

timedatectl status && echo "======= INFO: Printed clock status ======"
echo ""

mkfs.fat -F32 "/dev/${boot}" && echo "====== INFO: Formated boot/efi on partition /dev/${boot} ======"
echo ""

mkfs.ext2 -L "${mapped_swap}" "/dev/${swap}" 1M && echo "====== INFO: Formated swap on partition /dev/${swap} ======"
echo ""

cryptsetup luksFormat --key-size 512 "/dev/${root}" && echo "====== INFO: Created LUKS root container -> partition /dev/${root} ======"
echo ""

cryptsetup open --type luks "/dev/${root}" "${mapped_root}" && echo "====== INFO: Unlocked LUKS root container ======"
echo ""

mkfs.btrfs "/dev/mapper/${mapped_root}" && echo "====== INFO: Format mapped device /dev/mapper/${mapped_root} ======="
echo ""

mount --options compress=lzo "/dev/mapper/${mapped_root}" /mnt/ && echo "====== INFO: Mount mapped /dev/mapper/${mapped_root} ======"
echo ""

btrfs subvolume create /mnt/@ && btrfs subvolume create /mnt/@snapshots && btrfs subvolume create /mnt/@home && btrfs subvolume list -p /mnt/ && echo "====== INFO: Create top-level subvolumes ======"
echo ""

umount /mnt && echo "====== INFO: Unmount the system partition ======"
echo ""

mount --options compress=lzo,subvol=@ "/dev/mapper/${mapped_root}" /mnt && mkdir /mnt/home && mount --options compress=lzo,subvol=@home "/dev/mapper/${mapped_root}" /mnt/home && mkdir /mnt/.snapshots && mount --options compress=lzo,subvol=@snapshots "/dev/mapper/${mapped_root}" /mnt/.snapshots && echo "====== INFO: Mounted top-level subvolumes ======"
echo ""

mkdir -p /mnt/var/cache/pacman && btrfs subvolume create /mnt/var/cache/pacman/pkg && btrfs subvolume create /mnt/var/abs && btrfs subvolume create /mnt/var/tmp && btrfs subvolume create /mnt/srv && echo "====== INFO: Create nested sub-volume ======"
echo ""

mkdir /mnt/boot && mount "/dev/${boot}" /mnt/boot && echo "====== INFO: Mount boot/ESP to /dev/${boot} ======"
echo ""

pacstrap /mnt base && echo "====== INFO: Installing the base package ======"
echo ""

genfstab -U /mnt >> /mnt/etc/fstab && cat /mnt/etc/fstab && echo "====== INFO: Executing fstab ======"
echo ""

arch-chroot /mnt && echo "====== INFO: Executing chroot ======"
echo ""

pacman -S --needed reflector && echo "====== INFO: Installed reflector ======"
echo ""

reflector --latest 200 --sort rate --save /etc/pacman.d/mirrorlist && echo "====== INFO: Executed reflector ======"
echo ""

pacman -S --needed linux-hardened base-devel btrfs-progs zsh && echo "====== INFO: Installed basic packages"

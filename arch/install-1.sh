#! /bin/sh

printf "\n\nCreate partitions and confirm, Assume 2 partitions\n\n"
fdisk -l
lsblk -l

printf "\n\nSet layout\n\n"
loadkeys la-latin1

printf "\n\nWifi\n\n"
wifi-menu -o

printf "\n\nUpdate the system clock, enable NTP\n\n"
timedatectl set-ntp true

printf "\n\nSee clock status\n\n"
timedatectl status

printf "\n\nFormat boot/efi -> partition sda1\n\n"
mkfs.fat -F32 /dev/sda1

printf "\n\nCreate LUKS root container -> partition sda2\n\n"
cryptsetup luksFormat --key-size 512 /dev/sda2
cryptsetup luksDump /dev/sda2

printf "\n\nUnlock LUKS root container\n\n"
cryptsetup open --type luks /dev/sda2 cryptroot

printf "\n\nFormat mapped device\n\n"
mkfs.btrfs /dev/mapper/cryptroot

printf "\n\nMount mapped\n\n"
mount --options compress=lzo /dev/mapper/cryptroot /mnt/

printf "\n\nCreate top-level subvolumes\n\n"
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@home

printf "\n\nUnmount the system partition\n\n"
umount /mnt

printf "\n\nMount top-level subvolumes\n\n"
mount --options compress=lzo,subvol=@ /dev/mapper/cryptroot /mnt
mkdir /mnt/home
mount --options compress=lzo,subvol=@home /dev/mapper/cryptroot /mnt/home
mkdir /mnt/.snapshots
mount --options compress=lzo,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots

printf "\n\nCreate nested sub-volumes\n\n"
mkdir -p /mnt/var/cache/pacman
btrfs subvolume create /mnt/var/cache/pacman/pkg
btrfs subvolume create /mnt/var/abs
btrfs subvolume create /mnt/var/tmp
btrfs subvolume create /mnt/srv

printf "\n\nMount boot/ESP\n\n"
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

printf "\n\nInstalling the base package\n\n"
pacstrap /mnt base base-devel btrfs-progs zsh

printf "\n\nExecuting fstab\n\n"
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

printf "\n\nExecuting chroot\n\n"
arch-chroot /mnt

printf "\n\nInstalling reflector\n\n"
pacman -S --needed reflector

printf "\n\nRunning reflector\n\n"
reflector --latest 200 --sort rate --save /etc/pacman.d/mirrorlis

printf "\n\nInstalling basic packages\n\n"
pacman -S --needed base-devel btrfs-progs zsh

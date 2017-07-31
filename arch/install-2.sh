#!/bin/bash

# Prepare logs
>install-2.log
>install-2.err
exec > >(tee -ia install-2.log) 2> >(tee -ia install-2.err >&2)

# Variables
root=$1
time_zone=$2
keyboard_layout=$3
keyboard_layout_x11=$4
hostname=$5
system_user=$6
wifi=$7
mapped_root=cryptroot

# Fail if variables unset
set -o nounset
# Fail if any error
set -o errexit

{
  pacman -S --needed --noconfirm reflector \
  && echo "====== INFO: Installed reflector ======" \
  && echo ""
} && {
  reflector --latest 200 --sort rate --save /etc/pacman.d/mirrorlist \
  && echo "====== INFO: Executed reflector ======" \
  && echo ""
} && {
  pacman -S --needed --noconfirm linux-hardened base-devel btrfs-progs zsh \
  && echo "====== INFO: Installed basic packages" \
  && echo ""
} && {
  ln -sf "/usr/share/zoneinfo/${time_zone}" /etc/localtime \
  && hwclock --systohc --utc \
  && date \
  && echo "====== INFO: Setted time zone ======" \
  && echo ""
} && {
  sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
  && sed -i 's/#es_CO.UTF-8 UTF-8/es_CO.UTF-8 UTF-8/g' /etc/locale.gen \
  && sed -i 's/#en_US ISO-8859-1/en_US ISO-8859-1/g' /etc/locale.gen \
  && sed -i 's/#es_CO ISO-8859-1/es_CO ISO-8859-1/g' /etc/locale.gen \
  && locale-gen \
  && echo "====== INFO: Generated locale ======" \
  && echo ""
} && {
  echo LANG=en_US.UTF-8 > /etc/locale.conf \
  && echo LANGUAGE=en_US >> /etc/locale.conf \
  && echo LC_ALL=C >> /etc/locale.conf \
  && echo "====== INFO: Defined locale ======" \
  && echo ""
} && {
  echo "====== INFO: Defining keyboard layout to ${keyboard_layout} ======" \
  && echo "KEYMAP=${keyboard_layout}" > /etc/vconsole.conf \
  && echo "====== INFO: Defined keyboard layout to ${keyboard_layout} ======" \
  && echo ""
} && {
  echo "====== INFO: Defined hosts with hostname ${hostname} ======" \
  && echo "127.0.1.1	${hostname}.localdomain	${hostname}" >> /etc/hosts \
  && echo "${hostname}" > /etc/hostname \
  && echo "====== INFO: Defined hosts ======" \
  && echo ""
} && {
  pacman -S --needed --noconfirm networkmanager network-manager-applet dhclient openntpd networkmanager-dispatcher-openntpd \
  && systemctl stop dhcpcd.service \
  && systemctl start NetworkManager.service \
  && systemctl enable NetworkManager.service \
  && echo "====== INFO: Configued network ======" \
  && echo ""
} && {
  if [ "${wifi}" == "true" ]
  then
    pacman -S --needed --noconfirm iw wpa_supplicant dialog \
    && echo "======= INFO: Setted wifi ======" \
    && echo ""
  fi
} && {
  echo "====== INFO: Setting root password ======" \
  && passwd \
  && echo "====== INFO: Setted root password ======" \
  && echo ""
} && {
  echo "====== INFO: Adding system user ${system_user} ======" \
  && useradd -m -g users -G wheel -s /bin/zsh "${system_user}" \
  && passwd "${system_user}" \
  && echo "====== INFO: Added system user ${system_user} ======" \
  && echo ""
} && {
  sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers \
  && echo "====== INFO: Uncommented %wheel ALL=All ======" \
  && echo ""
} && {
  sed -i 's/BINARIES=""/BINARIES="/usr/bin/btrfs"/g' /etc/mkinitcpio.conf \
  && sed -i 's/HOOKS="base udev autodetect modconf block filesystems keyboard fsck"/HOOKS="base udev autodetect modconf block keymap encrypt filesystems keyboard fsck"/g' /etc/mkinitcpio.conf \
  && mkinitcpio -p linux \
  && echo "====== INFO: Executed mkinitcpio ======" \
  && echo ""
} && {
  pacman -S --needed --noconfirm grub efibootmgr intel-ucode os-prober \
  && echo "====== INFO: Installed packages for GRUB ======" \
  && echo ""
} && {
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub \
  && sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice=/dev/{root}:{mapped_root}"/g' /etc/default/grub \
  && echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub \
  && grub-mkconfig --output /boot/grub/grub.cfg \
  && echo "Installed GRUB" \
  && echo ""
} && {
  echo "====== INFO: Exiting new system ======"
  echo "Unmount all partitions with: umount -R /mnt"
  echo "Close cryptroot with: cryptsetup close cryptroot"
  echo "After reboot please execute: localectl --no-convert set-x11-keymap ${keyboard_layout_x11}"
  exit
}

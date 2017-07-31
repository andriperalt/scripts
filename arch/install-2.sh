#!/bin/bash

# Prepare logs
>install-2.log
>install-2.err
exec > >(tee -ia install-2.log) 2> >(tee -ia install-2.err >&2)

# Variables
time_zone=$1
keyboard_layout=$2
keyboard_layout_x11=$3
hostname=$4
system_user=$5
wifi=$6

echo "The following must have been configured:"
echo "  + /etc/crypttab"
echo "  + /etc/fstab"
echo "  + /etc/hosts"
echo "  + /etc/mkinitcpio.conf"

# Fail if variables unset
set -o nounset
# Fail if any error
set -o errexit

{
  pacman -S --needed reflector \
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
  echo "KEYMAP=${keyboard_layout}" > /etc/vconsole.conf \
  && echo "====== INFO: Defined keyboard layout ======" \
  && echo ""
} && {
  localectl set-x11-keymap "${keyboard_layout_x11}" \
  && echo "====== INFO: Defined keyboard layout for X11 ======" \
  && echo ""
} && {
  echo "${hostname}" > /etc/hostname \
  && echo "====== INFO: Defined Hostname ======" \
  && echo ""
} && {
  pacman -S --needed networkmanager network-manager-applet dhclient openntpd networkmanager-dispatcher-openntpd \
  && systemctl stop dhcpcd.service \
  && systemctl start NetworkManager.service \
  && systemctl enable NetworkManager.service \
  && echo "====== INFO: Configued network ======" \
  && echo ""
} && {
  if [ "${wifi}" == "true" ]
  then
    pacman -S --needed iw wpa_supplicant dialog \
    && echo "======= INFO: Setted wifi ======" \
    && echo ""
  fi
} && {
  passwd \
  && echo "====== INFO: Setted root password ======" \
  && echo ""
} && {
  useradd -m -g users -G wheel -s /bin/zsh "${system_user}" \
  && passwd "${system_user}" \
  && echo "====== INFO: Added system user ======" \
  && echo ""
} && {
  EDITOR=nano visudo \
  && echo "====== INFO: Uncommented %wheel ALL=All ======" \
  && echo ""
} && {
  mkinitcpio -p linux \
  && echo "====== INFO: Executed mkinitcpio ======" \
  && echo ""
} && {
  pacman -S --needed grub efibootmgr intel-ucode os-prober \
  && echo "====== INFO: Installed packages for GRUB ======" \
  && echo ""
} && {
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub \
  nano /etc/default/grub \
  && grub-mkconfig --output /boot/grub/grub.cfg \
  && echo "Installed GRUB" \
  && echo ""
} && {
  echo "====== INFO: Exiting new system ======"
  echo "Unmount all partitions with: umount -R /mnt"
  echo "Close cryptroot with: cryptsetup close cryptroot"
  exit
}

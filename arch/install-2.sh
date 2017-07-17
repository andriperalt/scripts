#! /bin/sh

printf "\n\nThe following must have been configured"
printf "/etc/crypttab -> if swap"
printf "/etc/fstab -> if swap"
printf "/etc/hosts"
printf "/etc/mkinitcpio.conf"
printf "/etc/default/grub"

printf "\n\nSetting time zone\n\n"
ln -sf /usr/share/zoneinfo/America/Bogota /etc/localtime
hwclock --systohc --utc

printf "\n\nSetting Locale\n\n"
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/#es_CO.UTF-8 UTF-8/es_CO.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/#en_US ISO-8859-1/en_US ISO-8859-1/g' /etc/locale.gen
sed -i 's/#es_CO ISO-8859-1/es_CO ISO-8859-1/g' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo LANGUAGE=en_US >> /etc/locale.conf
echo LC_ALL=C >> /etc/locale.conf
echo "KEYMAP=la-latin1" > /etc/vconsole.conf
localectl set-x11-keymap latam

printf "\n\nDefining Hostname\n\n"
echo "s4n-arpp" > /etc/hostname

printf "\n\nConfiguring network\n\n"
pacman -S --needed networkmanager network-manager-applet dhclient iw wpa_supplicant dialog
systemctl stop dhcpcd.service
systemctl start NetworkManager.servic
systemctl enable NetworkManager.service

printf "\n\nSet root password\n\n"
passwd

printf "\n\nAdding system user\n\n"
useradd -m -g users -G wheel -s /bin/zsh andres
passwd andres

printf "\n\nUncomment %wheel ALL=All\n\n"
EDITOR=nano visudo

printf "\n\nExecuting mkinit\n\n"
mkinitcpio -p linux

printf "\n\nInstalling packages for GRUB\n\n"
pacman -S --needed grub efibootmgr intel-ucode os-prober

printf "\n\nInstalling GRUB\n\n"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
grub-mkconfig --output /boot/grub/grub.cfg

printf "\n\nExiting new system\n\n"
exit

printf "\n\nUnmount all partitions and close cryptroot\n\n"
umount -R /mnt
cryptsetup close cryptroot

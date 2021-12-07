#!/bin/bash

# Add some custom variables here:
hostname=bbk
localuser=bbk

# Change your zoneinfo if needed:
ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime
hwclock --systohc

# Method to set locale should e refined:
# sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
# sed -i -e 's/# nb_NO.UTF-8 UTF-8/nb_NO.UTF-8 UTF-8/' /etc/locale.gen && \  
# sed -i '177s/.//' /etc/locale.gen

# echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
echo 'nb_NO.UTF-8 UTF-8' >> /etc/locale.gen

locale-gen
echo "LANG=nb_NO.UTF-8" >> /etc/locale.conf
echo "KEYMAP=no" >> /etc/vconsole.conf
echo "$hostname" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts
echo root:password | chpasswd

# You can add xorg to the installation packages, I usually add it at the DE or WM install script
# You can remove the tlp package if you are installing on a desktop or vm

# pacman -Syy
sed -i 's/^#Para/Para/' /etc/pacman.conf
pacman -S --needed reflector rsync
reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syyu 

# See pkglist.txt for details and change to your needs
pacman -Sy --needed - < pkglist.txt

# pacman -S --noconfirm xf86-video-amdgpu
pacman -S --noconfirm nvidia-lts nvidia-utils nvidia-settings
pacman -S --noconfirm xf86-video-intel

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
# systemctl enable bluetooth
systemctl enable cups
systemctl enable sshd
systemctl enable avahi-daemon
# systemctl enable tlp # You can comment this command out if you didn't install tlp, see above
# systemctl enable reflector.timer
systemctl enable fstrim.timer
# systemctl enable libvirtd
# systemctl enable firewalld
systemctl enable acpid

useradd -m $localuser
echo $localuser:password | chpasswd
usermod -aG libvirt wheel $localuser

# Is this a viable method????
# echo "$localuser ALL=(ALL) ALL" >> /etc/sudoers.d/$localuser


printf "\e[1;32mDone! Type exit, umount -R /mnt and reboot.\e[0m"


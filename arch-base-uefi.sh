#!/bin/bash

# Add some custom variables here:
hostname=test
localuser=test

echo "-------------------------------------------------"
echo "       Setup Language to NO and set locale       "
echo "-------------------------------------------------"
sed -i 's/^#nb_NO.UTF-8 UTF-8/nb_NO.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone Europe/Oslo
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="nb_NO.UTF-8" LC_TIME="nb_NO.UTF-8"
localectl --no-ask-password set-keymap no
hwclock --systohc

echo "KEYMAP=no" >> /etc/vconsole.conf
echo "$hostname" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts
echo root:password | chpasswd

# You can add xorg to the installation packages, I usually add it at the DE or WM install script
# You can remove the tlp package if you are installing on a desktop or vm

################
# Optimize mkpkg
################

nc=$(grep -c ^processor /proc/cpuinfo)
echo "You have " $nc" cores."
echo "-------------------------------------------------"
echo "Changing the makeflags for "$nc" cores."
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -gt 8000000 ]]; then
sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
echo "Changing the compression settings for "$nc" cores."
sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
fi

######################################################################
# Enable parallell download, install reflector, enable multilib and optimize mirrorlist
######################################################################

sed -i 's/^#Para/Para/' /etc/pacman.conf
pacman -S --needed reflector rsync
reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm
pacman -Syyu 

# See pkglist.txt for details and change to your needs
pacman -Sy --needed --noconfirm - < pkglist.txt

################################################
# determine processor type and install microcode
################################################
proc_type=$(lscpu | awk '/Vendor ID:/ {print $3}')
case "$proc_type" in
	GenuineIntel)
		print "Installing Intel microcode"
		pacman -S --noconfirm intel-ucode
		proc_ucode=intel-ucode.img
		;;
	AuthenticAMD)
		print "Installing AMD microcode"
		pacman -S --noconfirm amd-ucode
		proc_ucode=amd-ucode.img
		;;
esac	

###################################
# Graphics Drivers find and install
###################################

if lspci | grep -E "NVIDIA|GeForce"; then
    pacman -S nvidia-lts nvidia-utils nvidia-settings --noconfirm --needed
	nvidia-xconfig
elif lspci | grep -E "Radeon"; then
    pacman -S xf86-video-amdgpu --noconfirm --needed
elif lspci | grep -E "Integrated Graphics Controller"; then
    pacman -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils --needed --noconfirm
fi

echo -e "\nDone!\n"

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

if ! source install.conf; then
	read -p "Please enter username:" username
echo "username=$username" >> ${HOME}/ArchTitus/install.conf
fi
if [ $(whoami) = "root"  ];
then
    useradd -m -G wheel,libvirt -s /bin/bash $username 
	passwd $username
	cp -R /root/ArchTitus /home/$username/
    chown -R $username: /home/$username/ArchTitus
	read -p "Please name your machine:" nameofmachine
	echo $nameofmachine > /etc/hostname
else
	echo "You are already a user proceed with aur installs"
fi


# Is this a viable method????
# echo "$localuser ALL=(ALL) ALL" >> /etc/sudoers.d/$localuser


printf "\e[1;32mDone! Type exit, umount -R /mnt and reboot.\e[0m"


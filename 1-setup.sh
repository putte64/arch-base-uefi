#!/usr/bin/env bash

exec 5> debug_setup.sh.txt
        BASH_XTRACEFD="5"
        PS4='$LINENO: '
	set -ex

## Load username etc from setup.conf
source /root/arch-base-uefi/install.conf
echo -ne "

echo "--------------------------------------"
echo "--          Network Setup           --"
echo "--------------------------------------"
pacman -S networkmanager dhclient --noconfirm --needed
systemctl enable --now NetworkManager

sleep 10

echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"
pacman -S --noconfirm --needed pacman-contrib curl
pacman -S --noconfirm --needed reflector rsync grub btrfs-progs arch-install-scripts git
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

sleep 15

nc=$(grep -c ^processor /proc/cpuinfo)
echo -ne "
-------------------------------------------------------------------------
                    You have " $nc" cores. And
			changing the makeflags for "$nc" cores. Aswell as
				changing the compression settings.
-------------------------------------------------------------------------
"
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -gt 8000000 ]]; then
sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
fi

sleep 10

echo "-------------------------------------------------"
echo "       Setup Language to NO and set locale       "
echo "-------------------------------------------------"
sed -i 's/^#nb_NO.UTF-8 UTF-8/nb_NO.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone ${TIMEZONE}
timedatectl --no-ask-password set-ntp 1
hwclock --systohc

localectl --no-ask-password set-locale LANG="nb_NO.UTF-8" LC_TIME="nb_NO.UTF-8"

# Set keymaps
localectl --no-ask-password set-keymap ${KEYMAP}

sleep 10

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

#Add parallel downloading
sed -i 's/^#Para/Para/' /etc/pacman.conf

# #Enable multilib
# sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
# pacman -Sy --noconfirm

echo -e "\nInstalling Base System\n"

######################################################
# See pkglist.txt for details and change to your needs
######################################################

# pacman -Sy --needed --noconfirm - < /root/arch-base-uefi/pkglist.txt

cat /root/arch-base-uefi/pkglist.txt | while read line 
do
    echo "INSTALLING: ${line}"
   sudo pacman -S --noconfirm --needed ${line}
done

sleeep 10

################################################
# determine processor type and install microcode
# ##############################################

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

echo "processor install ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"
echo $proc_type
sleep 10

# Graphics Drivers find and install
if lspci | grep -E "NVIDIA|GeForce"; then
    pacman -S nvidia-lts nvidia-settings nvidia-utils --noconfirm --needed
	
elif lspci | grep -E "Radeon"; then
    pacman -S xf86-video-amdgpu --noconfirm --needed
    
elif lspci | grep -E "Integrated Graphics Controller"; then
    pacman -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils --needed --noconfirm
fi
echo -e "\nDone!\n"

# User create and password setting
if ! source /root/arch-base-uefi/install.conf; then
	read -p "Please enter username:" username
echo "username=$username" >> ${HOME}/arch-base-uefi/install.conf
fi

if [ $(whoami) = "root"  ];
then
    useradd -m -G wheel -s /bin/bash $username 
	passwd $username
	cp -R /root/arch-base-uefi /home/$username/
    chown -R $username: /home/$username/arch-base-uefi
	read -p "Please name your machine:" nameofmachine
	echo $nameofmachine > /etc/hostname
else
	echo "You are already a user proceed with aur installs"
fi

echo " ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"
echo " ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"
echo " Done with 1-setup script "
echo " ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"
echo " ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"

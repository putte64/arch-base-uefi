#!/usr/bin/env bash

exec 5> debug_setup.sh.txt
        BASH_XTRACEFD="5"
        PS4='$LINENO: '
	set -ex

## Load username etc from install.conf
source /root/arch-base-uefi/install.conf
echo -ne "

echo "--------------------------------------"
echo "--          Network Setup           --"
echo "--------------------------------------"
"

pacman -S networkmanager network-manager-applet dhclient --noconfirm --needed
systemctl enable NetworkManager

sleep 10

echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"
pacman -S --noconfirm --needed pacman-contrib curl
pacman -S --noconfirm --needed reflector rsync grub arch-install-scripts git
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

ln -sf /usr/share/zoneinfo/"$(curl --fail https://ipapi.co/timezone)" /etc/localtime
hwclock --systohc
sed -i 's/^#nb_NO.UTF-8 UTF-8/nb_NO.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
#timedatectl --no-ask-password set-timezone ${TIMEZONE}
timedatectl --no-ask-password set-ntp true


localectl --no-ask-password set-locale LANG="nb_NO.UTF-8" LC_TIME="nb_NO.UTF-8"

# Set keymaps
# localectl --no-ask-password set-keymap ${KEYMAP}
echo "KEYMAP=no" >> /etc/vconsole.conf

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

echo -ne "
#######################################################
#
# Packages installed from pkglist.txt
#
#######################################################
"
sleep 10

echo -ne "
################################################
# determine processor type and install microcode
# ##############################################
"

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

echo -ne "
-------------------------------------------------------------------------
                    Installing Graphics Drivers
-------------------------------------------------------------------------
"

gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    pacman -S nvidia-lts nvidia-utils --noconfirm --needed
	nvidia-xconfig
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    pacman -S xf86-video-amdgpu --noconfirm --needed
elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
    pacman -S libva-intel-driver libvdpau-va-gl vulkan-intel libva-intel-driver libva-utils --needed --noconfirm
elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
    pacman -S libva-intel-driver libvdpau-va-gl n-intel vulkan-intel libva-intel-driver libva-utils --needed --noconfirm
fi
echo -ne "
-------------------------------------------------------------------------
                    Adding User
-------------------------------------------------------------------------
"

#SETUP IS WRONG THIS IS RUN
if ! source /root/arch-base-uefi/install.conf; then
	# Loop through user input until the user gives a valid username
	while true
	do 
		read -p "Please enter username:" username
		# username regex per response here https://unix.stackexchange.com/questions/157426/what-is-the-regex-to-validate-linux-users
		# lowercase the username to test regex
		if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]
		then 
			break
		fi 
		echo "Incorrect username."
	done 
# convert name to lowercase before saving to setup.conf
echo "username=${username,,}" >> ${HOME}/arch-base-uefi/install.conf

    #Set Password
    read -p "Please enter password:" password
echo "password=${password,,}" >> ${HOME}/arch-base-uefi/install.conf

    # Loop through user input until the user gives a valid hostname, but allow the user to force save 
	while true
	do 
		read -p "Please name your machine:" nameofmachine
		# hostname regex (!!couldn't find spec for computer name!!)
		if [[ "${nameofmachine,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]
		then 
			break 
		fi 
		# if validation fails allow the user to force saving of the hostname
		read -p "Hostname doesn't seem correct. Do you still want to save it? (y/n)" force 
		if [[ "${force,,}" = "y" ]]
		then 
			break 
		fi 
	done 

    echo "nameofmachine=${nameofmachine,,}" >> ${HOME}/arch-base-uefi/install.conf
fi


sleep 10

if [ $(whoami) = "root"  ]; then
    groupadd libvirt
    useradd -m -G wheel,libvirt -s /bin/bash $USERNAME
    echo "$USERNAME ALL=(ALL) ALL" >> /etc/sudoers.d/$USERNAME

# use chpasswd to enter $USERNAME:$password
    echo "$USERNAME:$PASSWORD" | chpasswd
	cp -R /root/arch-base-uefi /home/$USERNAME/
    chown -R $USERNAME: /home/$USERNAME/arch-base-uefi
# enter $nameofmachine to /etc/hostname
	echo $nameofmachine > /etc/hostname
else
	echo "You are already a user proceed with aur installs"
fi
if [[ ${FS} == "luks" ]]; then
# Making sure to edit mkinitcpio conf if luks is selected
# add encrypt in mkinitcpio.conf before filesystems in hooks
    sed -i 's/filesystems/encrypt filesystems/g' /etc/mkinitcpio.conf
# making mkinitcpio with linux kernel
    mkinitcpio -p linux
fi
echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 2-user.sh
-------------------------------------------------------------------------
"

#!/usr/bin/env bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"

iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm pacman-contrib terminus-font
setfont ter-112n
sed -i 's/^#Para/Para/' /etc/pacman.conf
pacman -S --noconfirm rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

echo -e "-------------------------------------------------------------------------"
echo -e "-Setting up $iso mirrors for faster downloads"
echo -e "-------------------------------------------------------------------------"

reflector -a 12 -c $iso,se,dk,nl,de -f 5 -l 20 --sort rate --sort country -p https --threads 2 --save /etc/pacman.d/mirrorlist
#############################mkdir /mnt


echo -e "\nInstalling prereqs...\n$HR"
###################pacman -S --noconfirm gptfdisk


echo "-------------------------------------------------"
echo "-------select your disk to format----------------"
echo "-------------------------------------------------"
lsblk
echo "Please enter disk to work on: (example /dev/sda)"
read DISK
echo "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"
read -p "are you sure you want to continue (Y/N):" formatdisk
case $formatdisk in

y|Y|yes|Yes|YES)
echo "--------------------------------------"
echo -e "\nFormatting disk...\n$HR"
echo "--------------------------------------"

# disk prep
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# create partitions
sgdisk -n 1::+300M --typecode=0:ef00 --change-name=1:'EFI' ${DISK} # partition 1 (EFI Partition)
sgdisk -n 2::+2G --typecode=1:8200 --change-name=2:'SWAP' ${DISK} # partition 2 (SWAP Partition)
sgdisk -n 3::+30G --typecode=2:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (ROOT Partition)
sgdisk -n 4::-0 --typecode=3:8300 --change-name=4:'HOME' ${DISK} # partition 4 (HOME Partition), default start, remaining-128M
if [[ ! -d "/sys/firmware/efi" ]]; then
    sgdisk -A 1:set:2 ${DISK}
fi

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lsblk -f
echo "Continuing in 30 Seconds ..." && sleep 60
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# make filesystems
echo -e "\nCreating Filesystems...\n$HR"
if [[ ${DISK} =~ "nvme" ]]; then
mkfs.vfat -n "EFI" "${DISK}p1"
mkswap -L "SWAP" "${DISK}p2"
swapon "${DISK}p2"
mkfs.ext4 -n "ROOT" "${DISK}p3"
mkfs.ext4 -n "HOME" "${DISK}p4"
else
mkfs.vfat -n "EFI" "${DISK}1"
mkswap -L "SWAP" "${DISK}2"
swapon "${DISK}2"
mkfs.ext4 -n "ROOT" "${DISK}3"
mkfs.ext4 -n "HOME" "${DISK}4"
fi
mount "${DISK}3" /mnt`
mkdir -p /mnt/{boot/efi,home}`
mount "${DISK}1" /mnt/boot/efi`
mount "${DISK}4" /mnt/home`

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lsblk -f
echo "Continuing in 30 Seconds ..." && sleep 60
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;;
*)
echo "Continuing in 30 Seconds ..." && sleep 30
# reboot now
;;
esac

echo "--------------------------------------"
echo "-- Arch Install on Main Drive       --"
echo "--------------------------------------"
pacstrap /mnt base base-devel linux-lts linux-firmware nano sudo archlinux-keyring wget git --noconfirm --needed
genfstab -U /mnt >> /mnt/etc/fstab

echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${SCRIPT_DIR} /mnt/root/arch-base-uefi
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist


echo "--------------------------------------"
echo "--GRUB BIOS Bootloader Install&Check--"
echo "--------------------------------------"
if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot ${DISK}
fi
echo -e "\nFINAL SETUP AND CONFIGURATION"
echo "--------------------------------------"
echo "-- GRUB EFI Bootloader Install&Check--"
echo "--------------------------------------"
if [[ -d "/sys/firmware/efi" ]]; then
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
fi
grub-mkconfig -o /boot/grub/grub.cfg

exit
umount -R /mnt

    echo "Rebooting in 4 Seconds ..." && sleep 1
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now

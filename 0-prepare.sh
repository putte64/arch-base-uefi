#!/usr/bin/env bash

  exec 5> debug_prepare.txt
        BASH_XTRACEFD="5"
        PS4='$LINENO: '
        set -ex

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
#mkdir /mnt

echo -e "\nInstalling prereqs...\n$HR"

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
sgdisk -n 0::+300M --typecode=0:ef00 --change-name=0:'EFI' ${DISK} # partition 1 (EFI Partition)
sgdisk -n 0::+2G --typecode=0:8200 --change-name=0:'SWAP' ${DISK} # partition 2 (SWAP Partition)
sgdisk -n 0::+30G --typecode=0:8304 --change-name=0:'ROOT' ${DISK} # partition 3 (ROOT Partition)
sgdisk -n 0::-128M --typecode=0:8302 --change-name=0:'HOME' ${DISK} # partition 4 (HOME Partition), default start, remaining-128M
#if [[ ! -d "/sys/firmware/efi" ]]; then
#    sgdisk -A 1:set:2 ${DISK}
#fi


# make filesystems
echo -e "\nCreating Filesystems...\n$HR"
if [[ ${DISK} =~ "nvme" ]]; then
mkfs.vfat "${DISK}p1"
mkfs.ext4 "${DISK}p3"
mkfs.ext4 "${DISK}p4"


mkswap "${DISK}p2"
swapon "${DISK}p2"
else
mkfs.vfat -F32 "${DISK}1"
mkfs.ext4 "${DISK}3"
mkfs.ext4 "${DISK}4"

mkswap "${DISK}2"
swapon "${DISK}2"
fi
mount "${DISK}3" /mnt
mkdir -p /mnt/{boot/efi,home}
mount "${DISK}1" /mnt/boot/efi
mount "${DISK}4" /mnt/home
;;
esac

echo "--------------------------------------"
echo "-- Arch Install on Main Drive       --"
echo "--------------------------------------"
pacstrap /mnt base base-devel linux-lts linux-firmware nano sudo archlinux-keyring wget git --noconfirm --needed

echo "Wait for packages to be installed!!!!" && sleep 5

genfstab -U /mnt >> /mnt/etc/fstab

echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf

mkdir /mnt/root/arch-base-uefi

echo "#################################################################"
echo "cp -R /root/arch-base-uefi /mnt/root/arch-base-uefi" && sleep 5
echo "#################################################################"

cp -R /root/arch-base-uefi /mnt/root/

cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist


echo "--------------------------------------"
echo " -SYSTEM READY FOR 1-arch-base-uefi-  "
echo "--------------------------------------"

#!/usr/bin/env bash

  exec 5> debug_preinstall.sh.txt
        BASH_XTRACEFD="5"
        PS4='$LINENO: '
        set -ex

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -ne "
-------------------------------------------------------------------------
Setting up mirrors for optimal download
-------------------------------------------------------------------------
"
source install.conf
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm --needed pacman-contrib terminus-font
setfont ter-v12n
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm --needed reflector rsync


echo -ne "
-------------------------------------------------------------------------
                    Setting up $iso mirrors for faster downloads
-------------------------------------------------------------------------
"
sleep 5
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

echo -ne "
-------------------------------------------------------------------------
                    Installing Prerequisites
-------------------------------------------------------------------------
"
sleep 5
pacman -S --noconfirm --needed gptfdisk

clear
echo -ne "
-------------------------------------------------------------------------
                    Formating Disk
-------------------------------------------------------------------------
"
sleep 5
# disk prep
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# create partitions
#sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
#sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
#sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
#if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
#    sgdisk -A 1:set:2 ${DISK}
#fi

# Create partitions spesific system
sgdisk -n 0::+300M --typecode=0:ef00 --change-name=0:'EFIBOOT' ${DISK} # partition 1 (EFI Partition)
sgdisk -n 0::+2G --typecode=0:8200 --change-name=0:'SWAP' ${DISK} # partition 2 (SWAP Partition)
sgdisk -n 0::+30G --typecode=0:8304 --change-name=0:'ROOT' ${DISK} # partition 3 (ROOT Partition)
sgdisk -n 0::-128M --typecode=0:8302 --change-name=0:'HOME' ${DISK} # partition 4 (HOME Partition), default start, remaining-128M
lsblk -f
sleep 15
clear

echo -ne "
-------------------------------------------------------------------------
                    Creating Filesystems
-------------------------------------------------------------------------
"
sleep 5
createsubvolumes () {
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@tmp
    btrfs subvolume create /mnt/@.snapshots
}

mountallsubvol () {
    mount -o ${mountoptions},subvol=@home /dev/mapper/ROOT /mnt/home
    mount -o ${mountoptions},subvol=@tmp /dev/mapper/ROOT /mnt/tmp
    mount -o ${mountoptions},subvol=@.snapshots /dev/mapper/ROOT /mnt/.snapshots
    mount -o ${mountoptions},subvol=@var /dev/mapper/ROOT /mnt/var
}

if [[ "${DISK}" =~ "nvme" ]]; then
    partition1=${DISK}p1
    partition2=${DISK}p2
    partition3=${DISK}p3
    partition4=${DISK}p4
else
    partition1=${DISK}1
    partition2=${DISK}2
    partition3=${DISK}3
    partition4=${DISK}4
fi

if [[ "${FS}" == "btrfs" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
    mkfs.btrfs -L ROOT ${partition3} -f
    mount -t btrfs ${partition3} /mnt
elif [[ "${FS}" == "ext4" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${partition1}
    mkfs.ext4 -L ROOT ${partition3}
    mkfs.ext4 -L HOME ${partition4}
fi

# checking if user selected btrfs
if [[ ${FS} =~ "btrfs" ]]; then
ls /mnt | xargs btrfs subvolume delete
btrfs subvolume create /mnt/@
umount /mnt
mount -t btrfs -o subvol=@ -L ROOT /mnt
fi

# mount target

mount -t ext4 ${partition3} /mnt
mkdir -p /mnt/{boot,home} &&
mount -t vfat -L EFIBOOT /mnt/boot
mount -t ext4 ${partition4} /mnt/home
mkswap ${partition2}
swapon ${partition2}


if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted can not continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi
lsblk -f
sleep 15
clear

echo -ne "
-------------------------------------------------------------------------
                    Arch Install on Main Drive + fstab
-------------------------------------------------------------------------
"
pacstrap /mnt base base-devel linux-lts linux-firmware vim nano sudo archlinux-keyring wget --noconfirm --needed
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${SCRIPT_DIR} /mnt${SCRIPT_DIR}
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

#echo "UUID=device_UUID none swap defaults 0 0" >> /mnt/etc/fstab
#genfstab -U /mnt >> /mnt/etc/fstab
sleep 5
clear

#echo -ne "
#-------------------------------------------------------------------------
#                    GRUB BIOS Bootloader Install & Check
#-------------------------------------------------------------------------
#"
#if [[ ! -d "/sys/firmware/efi" ]]; then
#    grub-install --boot-directory=/mnt/boot ${DISK}
#fi
echo -ne "
-------------------------------------------------------------------------
                    Checking for low memory systems <8G
-------------------------------------------------------------------------
"
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -lt 8000000 ]]; then
    # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
    mkdir /mnt/opt/swap # make a dir that we can apply NOCOW to to make it btrfs-friendly.
    chattr +C /mnt/opt/swap # apply NOCOW, btrfs needs that.
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile # set permissions.
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    # The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the system itself.
    echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab # Add swap to fstab, so it KEEPS working after installation.
fi
echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 1-setup.sh
-------------------------------------------------------------------------
"
sleep 5
clear

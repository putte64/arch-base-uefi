# arch-base-uefi
*WARNING: **NOT** intended for public use. Use at your own risk.
1. If needed, load your keymap : `## loadkeys no`
2. Check that we are indeed using EFI : `## ls /sys/firmware/efi/efivars`
3. Check for internet connection : `## ping archlinux.org`
4. Check synced time service `## timedatectl set-ntp true` (check status with `## timedatectl status`)
## Partition the disk and format.
    Find your drive `## fdisk -l` or `## lsblk`
    `## gdisk /dev/XXX`
    Make EFI partition 512M ef00
    Make SWAP partition 4G 8200
    Make root partition 50G 8300
    Make home partition "rest minus some space on SSD" 8300
    
    `## mkfs.vfat /dev/XXX1`
    `## mkswap /dev/XXX2`
    `## swapon /dev/XXX2`
    `## mkfs.ext4 /dev/XXX3`
    `## mkfs.ext4 /dev/XXX4`
    
## Mount the partitions
    `## mount /dev/XXX3 /mnt`
    `## mkdir -p /mnt/efi`
    `## mount /dev/XXX1 /mnt/efi`
    `## mkdir /mnt/home`
    `## mount /dev/XXX4 /mnt/home`

## Installing base packages
    *NOTE: Live media uses reflector to sort mirrorlist, pacstrap copies that list to install*
1. Install the base packages into /mnt (`## pacstrap /mnt base base-devel linux-lts linux-firmware sof-firmware git nano intel-ucode`)
1. Generate the FSTAB file with: `## genfstab -U /mnt >> /mnt/etc/fstab`
1. Chroot in with: `## arch-chroot /mnt`
1. Download the git repository with: `## git clone https://github.com/putte64/arch-base-uefi`
1. `## cd arch-basic`
1. `## chmod +x arch-base-uefi.sh`
1. `## run with ./arch-base-uefi.sh`

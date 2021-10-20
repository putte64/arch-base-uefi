# arch-base-uefi
1. If needed, load your keymap : `## loadkeys no`
2. Check that we are indeed using EFI : `## ls /sys/firmware/efi/efivars`
3. Check for internet connection : `## ping archlinux.org`
4. Check synced time service `## timedatectl set-ntp true` (check status with `## timedatectl status`)
## Partition the disk
1. Format the partitions
    Find your drive `## fdisk -l` or `## lsblk`
    
8. Mount the partitions
## Installing base packages
    *NOTE: Live media uses reflector to sort mirrorlist, pacstrap copies that list to install*
10. Install the base packages into /mnt (`## pacstrap /mnt base base-devel linux-lts linux-firmware sof-firmware git nano intel-ucode`)
11. Generate the FSTAB file with: `## genfstab -U /mnt >> /mnt/etc/fstab`
12. Chroot in with: `## arch-chroot /mnt`
13. Download the git repository with: `## git clone https://github.com/putte64/arch-base-uefi`
14. `## cd arch-basic`
15. `## chmod +x install-uefi.sh`
16. `## run with ./install-uefi.sh`

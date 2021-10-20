# arch-base-uefi
1. If needed, load your keymap : `## loadkeys no`
2. Check that we are indeed using EFI : ## ls /sys/firmware/efi/efivars
3. Check for internet connection : ## ping archlinux.org
4. Check synced time service ## timedatectl set-ntp true (check status with ## timedatectl status)
5. Refresh the servers with pacman -Syy
## Partition the disk
1. Format the partitions
8. Mount the partitions
9. Install the base packages into /mnt (pacstrap /mnt base linux linux-firmware git vim intel-ucode (or amd-ucode))
10. Generate the FSTAB file with genfstab -U /mnt >> /mnt/etc/FSTAB
11. Chroot in with arch-chroot /mnt
12. Download the git repository with git clone https://gitlab.com/eflinux/arch-basic
13. cd arch-basic
14. chmod +x install-uefi.sh
15. run with ./install-uefi.sh

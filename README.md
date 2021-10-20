# arch-base-uefi
1. If needed, load your keymap : ## loadkeys no
2. Check that we are indeed using EFI : ## ls /sys/firmware/efi/efivars
3. Refresh the servers with pacman -Syy
4. Partition the disk
5. Format the partitions
6. Mount the partitions
7. Install the base packages into /mnt (pacstrap /mnt base linux linux-firmware git vim intel-ucode (or amd-ucode))
8. Generate the FSTAB file with genfstab -U /mnt >> /mnt/etc/FSTAB
9. Chroot in with arch-chroot /mnt
10. Download the git repository with git clone https://gitlab.com/eflinux/arch-basic
11. cd arch-basic
12. chmod +x install-uefi.sh
13. run with ./install-uefi.sh

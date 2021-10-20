# arch-base-uefi
1. If needed, load your keymap
1. Refresh the servers with pacman -Syy
1. Partition the disk
1. Format the partitions
1. Mount the partitions
1. Install the base packages into /mnt (pacstrap /mnt base linux linux-firmware git vim intel-ucode (or amd-ucode))
1. Generate the FSTAB file with genfstab -U /mnt >> /mnt/etc/FSTAB
1. Chroot in with arch-chroot /mnt
1. Download the git repository with git clone https://gitlab.com/eflinux/arch-basic

cd arch-basic
chmod +x install-uefi.sh
run with ./install-uefi.sh

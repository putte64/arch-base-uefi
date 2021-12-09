#!/bin/bash

    bash 0-preinstall.sh
    arch-chroot /mnt /root/arch-base-uefi/1-arch-base-uefi.sh
    source /mnt/root/arch-base-uefi/install.conf
    arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/arch-base-uefi/2-user.sh
    arch-chroot /mnt /root/arch-base-uefi/3-post-setup.sh

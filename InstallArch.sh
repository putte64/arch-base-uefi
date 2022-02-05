#!/bin/bash
        
# Find the name of the folder the scripts are in
        setfont ter-v14n
        SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    sleep 10   
    bash startup.sh
    source $SCRIPT_DIR/install.conf
    bash 0-preinstall.sh
    arch-chroot /mnt /root/arch-base-uefi/1-setup.sh
    arch-chroot /mnt /usr/bin/runuser -u $USERNAME -- /home/$USERNAME/arch-base-uefi/2-user.sh
    arch-chroot /mnt /root/arch-base-uefi/3-post-setup.sh
    
    echo "###################################################################################"
    echo "###################################################################################"
    echo "  The End The End The End The End The End The End The End The End The End The End  "
    echo "  The End The End The End The End The End The End The End The End The End The End  "
    echo "###################################################################################"
    echo "###################################################################################"

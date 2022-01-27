#!/bin/bash

        exec 5> debug_output.txt
        BASH_XTRACEFD="5"
        PS4='$LINENO: '
        set -e
        
# Find the name of the folder the scripts are in
        setfont ter-v22b
        SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
        
    bash startup.sh
    source $SCRIPT_DIR/setup.conf
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

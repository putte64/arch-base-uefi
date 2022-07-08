#!/bin/bash

set -eu -o pipefail
        
# Find the name of the folder the scripts are in
        setfont ter-v12n
        SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

    ( bash startup.sh )|& tee startup.log
    source $SCRIPT_DIR/install.conf
    ( bash 0-preinstall.sh )|& tee 0-preinstall.log
    ( arch-chroot /mnt /root/arch-base-uefi/1-setup.sh )|& tee 1-setup.log
    ( arch-chroot /mnt /usr/bin/runuser -u $USERNAME -- /home/$USERNAME/arch-base-uefi/2-user.sh )|& tee 2-user.log
    ( arch-chroot /mnt /root/arch-base-uefi/3-post-setup.sh )|& tee 3-post-setup.log
    cp -v *.log /mnt/home/$USERNAME
    
    echo "###################################################################################"
    echo "###################################################################################"
    echo "  The End The End The End The End The End The End The End The End The End The End  "
    echo "  The End The End The End The End The End The End The End The End The End The End  "
    echo "###################################################################################"
    echo "###################################################################################"

#!/usr/bin/env bash

exec 5> debug_post-setup.sh.txt
        BASH_XTRACEFD="5"
        PS4='$LINENO: '
        set -ex

echo -ne "
-------------------------------------------------------------------------
Final Setup and Configurations
GRUB EFI Bootloader Install & generate fstab
-------------------------------------------------------------------------
"
source /root/arch-base-uefi/install.conf
genfstab -U / >> /etc/fstab
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo -ne "
-------------------------------------------------------------------------
                    Enabling Login Display Manager and setup theme
-------------------------------------------------------------------------
"
echo -e "\nEnabling Login Display Manager"
systemctl enable sddm.service
echo -e "\nSetup SDDM Theme"
cat <<EOF > /etc/sddm.conf
[Theme]
Current=Nordic
EOF

echo -ne "
-------------------------------------------------------------------------
                    Enabling Essential Services
-------------------------------------------------------------------------
"

systemctl enable cups.service
ntpd -qg
systemctl enable ntpd.service
#systemctl disable dhcpcd.service
#systemctl stop dhcpcd.service
#systemctl enable NetworkManager.service

echo -ne "
-------------------------------------------------------------------------
                    Cleaning 
-------------------------------------------------------------------------
"

# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Remove installfiles
rm -r /root/arch-base-uefi
rm -r /home/$USERNAME/arch-base-uefi

# Replace in the same state
cd $pwd

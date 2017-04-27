#!/bin/bash

usage(){
        echo "$0 target"
}

no_host_entry(){
        echo "There is no $target in /etc/hosts"
        exit 1
}

check_and_set_params(){
dev=/dev/sdb
mntpoint=/mnt/root
SERVER=192.168.0.101

if [ "$target" == "" ] ; then
        usage 
        exit 1
fi

read address hostname <<<$(getent hosts $target)

[ "$address" == "" ] && no_host_entry
[ "$hostname" == "" ] && no_host_entry

if ping -c 1 -w 1 $address  > /dev/null ; then
        echo "The $address is already taken by somebody!"
        exit 1
fi
}

target=$1
check_and_set_params

sfdisk -D $dev << EOF
,,L
EOF

mkfs.ext4 -L rootfs ${dev}1

mkdir ${mntpoint}
mount -L rootfs ${mntpoint}

wget -O - http://$SERVER:8088/jessie64/rootfs.tgz |tar zxf - -C ${mntpoint}/

grub-install --boot-directory=${mntpoint}/boot/ ${dev}

echo "${dev}1 / ext4 defaults 0 0" >  ${mntpoint}/etc/fstab

cat <<EOF >${mntpoint}/boot/grub/grub.cfg
set default=0
set timeout=5
set root=(hd1,1)

serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
terminal_input serial console
terminal_output serial console

insmod png
if background_image /boot/grub/moreblue-orbit-grub.png ; then
  set color_normal=black/black
  set color_highlight=magenta/black
else
  set menu_color_normal=cyan/blue
  set menu_color_highlight=white/blue
fi

insmod part_msdos
insmod ext2

menuentry "Debian Linux serial" {
        set root=(hd0,1)
        set gfxpayload=1280x1024x24,1280x1024
        linux   /boot/vmlinuz-3.16.0-4-amd64 root=${dev}1 panic=10 console=tty0 console=ttyS0,115200n8 cgroup_enable=memory
        initrd  /boot/initrd.img-3.16.0-4-amd64
}
menuentry "Debian Linux" {
        set root=(hd0,1)
        set gfxpayload=1280x1024x24,1280x1024
        linux   /boot/vmlinuz-3.16.0-4-amd64 root=${dev}1 panic=10 cgroup_enable=memory
        initrd  /boot/initrd.img-3.16.0-4-amd64
}
menuentry "Debian Linux serial" {
        set root=(hd0,1)
        linux   /boot/vmlinuz-3.16.0-4-amd64 root=${dev}1 panic=10 console=tty0 console=ttyS0,115200n8 cgroup_enable=memory
        initrd  /boot/initrd.img-3.16.0-4-amd64
}
EOF

echo $hostname > ${mntpoint}/etc/hostname 

cat <<EOF> ${mntpoint}/etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0

iface eth0 inet static
        address         $address
        network         192.168.0.0
        broadcast       192.168.0.255
        netmask         255.255.255.0
        gateway         192.168.0.1

source-directory /etc/network/interfaces.d
EOF



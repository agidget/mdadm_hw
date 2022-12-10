#!/bin/bash

# raid10
cd /vagrant
lsblk > output.log
fdisk -l >> output.log
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm --create --verbose /dev/md0 -l 10 --raid-devices=5 /dev/sd[b-f]
echo "RAID10 is created" >> output.log
lsblk >> output.log
cat /proc/mdstat >> output.log

# fail
mdadm --detail /dev/md0
mdadm /dev/md0 --fail /dev/sde
mdadm /dev/md0 --remove /dev/sde
mdadm /dev/md0 --add /dev/sde
echo "RAID is fixed" >> output.log
cat /proc/mdstat >> output.log

# mdadm.conf
mdadm --detail --scan --verbose >> output.log
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/{print}' >> /etc/mdadm/mdadm.conf
echo "mdadm.conf content" >> output.log
cat /etc/mdadm/mdadm.conf >> output.log

# gpt partition
parted -s /dev/md0 mklabel gpt
parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%
for i in $(seq 1 5); do mkfs.ext4 /dev/md0p$i; done
mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
echo "gpt partition is done" >> output.log
lsblk >> output.log


# # mdadm clean raids
# sudo mdadm --stop md0
# sudo wipefs -a /dev/sd[b-f]
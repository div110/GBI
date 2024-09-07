#! /bin/bash


clear
read -p "Silence Output?(NOT RECOMMENDED) [y/N]? " quiet


if [ "$quiet" = "y" ]; then
exec > /dev/null

fi

exec 2> err_log
echo "ALL errors are redirected to err_log"
#sleep 1.5
echo "the Installer will create 3 Partitions on your Disk"
#sleep 1.5
echo "Select your Disk"

cd /dev/
select diskname in *;

do
	echo "Selecting $diskname..."
	break;
done 2>&1

#fdisk BLOCK
#/
#/
#/
#/
#/
#fdisk BLOCK


echo "Select Filesystem for your Root Partition"
select filesystem in "XFS" "btrfs" "ext4";
do 
	echo "Choosing $filesystem..."
	break
done 2>&1


#mkfs.vfat -F 32 /dev/

#mkfs.$filesystem /dev/$diskname

#mkswap /dev/$diskname
#swapon /dev/$diskname


#mkdir --parents /mnt/gentoo
#mkdir --parents /mnt/gentoo/efi


#mount /dev/$diskname /mnt/gentoo




#cd /mnt/gentoo
#chronyd -q


read -p "Provide Link for Stage3 Tarball / Leave empty for automatic download " stage3 2>&1		#This downloads "core" Gentoo

if [ -z "$stage3" ]; then
	#wget http://ftp.fi.muni.cz/pub/linux/gentoo/releases/amd64/autobuilds/current-stage3-amd64-desktop-openrc/stage3-amd64-desktop-openrc-20240901T170410Z.tar.xz
	echo "base"
else
	#wget $stage3
	echo "custom"
fi




#tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner





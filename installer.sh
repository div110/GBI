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


read -p "Provide Link for Stage3 Tarball / Leave empty for automatic download(Desktop) " stage3 2>&1		#This downloads "core" Gentoo

if [ -z "$stage3" ]; then
	#wget http://ftp.fi.muni.cz/pub/linux/gentoo/releases/amd64/autobuilds/current-stage3-amd64-desktop-openrc/stage3-amd64-desktop-openrc-20240901T170410Z.tar.xz
	echo "base"
else
	#wget $stage3
	echo "custom"
fi




#tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner



echo "Configuration of CFlags and CXXFlags..." #CFlags and CXXFlags serve as a tool to optimize GCC and C++ compilers
#sleep 1.5


touch /mnt/gentoo/etc/portage/make.conf

echo """# Compiler flags to set for all languages
COMMON_FLAGS=\"-march=native -O2 -pipe\"
# Use the same settings for both variables
CFLAGS=\"${COMMON_FLAGS}\"
CXXFLAGS=\"${COMMON_FLAGS}\"""" > /mnt/gentoo/etc/portage/make.conf


########################	THREADS DISCOVERY
hreads="$(nproc)"
threads=$((threads+1))
########################


########################	RAM DISCOVERY
halfram=$(sudo cat /proc/meminfo | head -n 1 | sed 's/[^0-9]//g')
halfram=$((($halfram/1000000)+2))
########################


echo "MAKEOPTS=\"-j$halfram -l$threads\"">> /mnt/gentoo/etc/make.conf




#DNS INFO
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/


#this is really boring
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run 

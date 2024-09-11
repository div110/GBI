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
read -p "Do you wish to use Automatic Disk Discovery? [yes/no]" auto_disk

#sleep 1.5
echo "Select your Disk"

cd /dev/
select diskname in *;

do
	echo "Selecting $diskname..."
	break;
done 2>&1


#automatic disk discovery
#
#lsblk -n -o 'NAME' --nodeps | head -n 1
#
#



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
echo "Architecture: Native; Optimization O2; Piping Allowed"

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



#chrooting into the new env
#ch/mnt/gentoo /bin/bash #root directory change
#source /etc/profile #using profile
#export PS1="(chroot) ${PS1}" #??????


mkdir /efi
#mount /dev/sda1 /efi /mounting efi partition to /efi directory

emerge-webrsync


#emerge --ask --verbose --oneshot app-portage/mirrorselect
#mirrorselect -i -o >> /etc/portage/make.conf

emerge --sync


eselect profile list 
read -p "Choose a Profile Number: " ProfileNumber
eselect profile set $ProfileNumber
echo "Configure Host for Binary Packages?"
select binary in "Yes" "No";
do 
	echo "Selecting $binary..."
	break
done 2>&1

if [ "$binary"="Yes" ]then;
######################
#Binhost Config Block#
######################
fi


#################
#USE FLAGS BLOCK#
#################



##CPU FLAGS##
echo "CPU Flags are set Automatically"
echo "Located at /etc/portage/package.use/00cpu-flags"
emerge --ask --oneshot app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags



##VIDEO_CARDS FLAG##
echo "SETTING GPU Flags"
echo "Select Your GPU Manufacturer: "
select videocard in "intel" "nvidia" "amdgpu"; #missing nouveau driver option
do
	
	echo "VIDEO_CARDS=\"$videocard\"" >> /etc/portage/make.conf
	echo "Setting VIDEO_CARDS to $videocard"
	break
done 2>&1


echo "LICENSES"
read -p "ACCEPT All Licenses? [y/n]" license
if [ "$license" = "y" ]; then
	echo "ACCEPT_LICENSE=\"*\"">>/etc/portage/make.conf
else
	#missing mechanism for choosing all allowed licenses
fi



emerge --ask --verbose --update --deep --newuse @world



emerge --ask --depclean

#OpenRC Timezones
select continent in $(ls /usr/share/zoneinfo);
select country in $(ls /usr/share/zoneinfo/Europe/); 
echo "$continent/$country" > /etc/timezone

emerge --config sys-libs/timezone-data


select locale in $(cat /usr/share/i18n/SUPPORTED);
do
	echo "		<====>"
	locale-gen
	break
done 2>&1


eselect locale list
read locale
eselect locale set $locale

env-update && source /etc/profile && export PS1="(chroot) ${PS1}"


emerge --ask sys-kernel/linux-firmware

emerge --ask sys-firmware/sof-firmware #to be safe
emerge --ask sys-firmware/intel-microcode #Just for Intel CPUs

##Bootloader##
#just GRUB for now

touch /etc/portage/package.use/installkernel
echo "sys-kernel/installkernel grub" >> /etc/portage/package.use/installkernel
emerge --ask sys-kernel/installkernel



##InitRamFS
echo "sys-kernel/installkernel dracut" >> /etc/portage/package.use/installkernel



##KERNEL CONFIG + INSTALL

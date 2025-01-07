#! /bin/bash


clear
read -p "Ztlumit výstup?(NEDOPORUČENÉ) [y/N]? " quiet


if [ "$quiet" = "y" ]; then
exec > /dev/null

fi

exec 2> err_log
echo "VŠECHNY errory budou přesměrovány do err_log"
#sleep 1.5
echo "Instalator vytvoří 3 oddíly na Vašem disku"
read -p "Přejete si použít automatický výber disku? [yes/no]" auto_disk

#sleep 1.5
echo "Vyberte disk:"

cd /dev/
select diskname in *;

do
	echo "Vybírám: $diskname..."
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


echo "Vyberte souborový systém pro váš Kořenový oddíl"
select filesystem in "XFS" "btrfs" "ext4";
do 
	echo "Formátuji na $filesystem..."
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


read -p "Zadejte URL Adresu Stage3 Tarballu (Prázdné pro automatické stažení[DESKTOP])" stage3 2>&1		#This downloads "core" Gentoo

if [ -z "$stage3" ]; then
	#wget http://ftp.fi.muni.cz/pub/linux/gentoo/releases/amd64/autobuilds/current-stage3-amd64-desktop-openrc/stage3-amd64-desktop-openrc-20240901T170410Z.tar.xz
	echo "Základní"
else
	#wget $stage3
	echo "Vlastní"
fi




#tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner



echo "Konfigurace CFlags a CXXFlags..." #CFlags and CXXFlags serve as a tool to optimize GCC and C++ compilers
#sleep 1.5


touch /mnt/gentoo/etc/portage/make.conf

echo """# Compiler flags to set for all languages
COMMON_FLAGS=\"-march=native -O2 -pipe\"
# Use the same settings for both variables
CFLAGS=\"${COMMON_FLAGS}\"
CXXFLAGS=\"${COMMON_FLAGS}\"""" > /mnt/gentoo/etc/portage/make.conf
echo "Architecture: Native; Optimization O2; Piping Allowed"

########################	ZJIŠŤOVÁNÍ VLÁKEN SYSTÉMU
hreads="$(nproc)"
threads=$((threads+1))
########################


########################	ZJIŠŤOVÁNÍ OPERAČNÍ PAMĚTI
halfram=$(sudo cat /proc/meminfo | head -n 1 | sed 's/[^0-9]//g')
halfram=$((($halfram/1000000)+2))
########################


echo "MAKEOPTS=\"-j$halfram -l$threads\"">> /mnt/gentoo/etc/make.conf



#DNS INFO
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/


#this is really boring :)
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run 



#změna kořene na nové prostředí
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
read -p "Vyberte číslo Profilu: " ProfileNumber
eselect profile set $ProfileNumber
echo "Chcete nakonfigurovat Binární Repositář?"
select binary in "Yes" "No";
do 
	echo "$binary..."
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
echo "CPU Flags jsou nastavny Automaticky"
echo "Umístěny v /etc/portage/package.use/00cpu-flags"
emerge --ask --oneshot app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags



##VIDEO_CARDS FLAG##
echo "Konfigurace GPU Flags"
echo "Vyberte výrobce Vaší grafické karty: "
select videocard in "intel" "nvidia" "amdgpu"; #missing nouveau driver option
do
	
	echo "VIDEO_CARDS=\"$videocard\"" >> /etc/portage/make.conf
	echo "VIDEO_CARDS = $videocard"
	break
done 2>&1


echo "LICENCE"
read -p "Přijmout všechny licence? [y/n]" license
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


#########################
##KERNEL CONFIG+COMPILE##
#########################

###DISTRIBUTION KERNELS###
echo "Kompilace Jádra: "
select binsrc in "Compile Localy" "Use Precompiled";
break
done
	

###############
#UNSTABLE IMHO#
###############
if [ "$binsrc" = "Compile Localy" ];then
	emerge --ask sys-kernel/gentoo-kernel
else
	emerge --ask sys-kernel/gentoo-kernel-bin #binary??? ew :/
fi

#
#Post Install/upgrade tasks
#

emerge --ask sys-kernel/gentoo-sources


eselect kernel list
read -p "Option: " KernelNumber
eselect kearnel set KernelNumber
################
#/UNSTABLE IMHO#
################



##fstab##
read -p "Kam připojovat USB zařízení?(Výchozí: /mnt/usb): " usbmount
sudo mkdir $usbmount

read -p "Will You Switch Storages Frequently?[y/n]: " uuid
if [ "$uuid" = "n" ]; then
echo """
/dev/sda1   /efi         vfat   	umask=0077     		0 2
/dev/sda2   none         swap   	sw                      0 0
/dev/sda3   /            $filesystem    defaults,noatime        0 1
#/dev/	    $usbmount    auto 		noauto,user		0 0
/dev/cdrom  /mnt/cdrom   auto    	noauto,user             0 0"""
else 
######################
#GPT DISK LABEL fstab#
######################
break

##Network##
echo "|Konfigurace sítě|"
select customname in "Custom hostname" "Random hostname";
if [ "$customname" = "Custom hostname" ]; then
	read -p "Enter hostname: " hostname
else
	hostname = $(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 6)
fi


echo $hostname > /etc/hostname
emerge --ask net-misc/dhcpcd
rc-update add dhcpcd default
rc-service dhcpcd start


emerge --ask --noreplace net-misc/netifrc 

select ipconfig in "Statická" "DHCP" "Custom";
case $ipconfig in

  Static)
    read -p "IP: " ip
    read -p "MASK: " mask
    read -p "Broadcast: " brd  #brdcal
    read -p "Router IP: " routerIP
    echo """config_eth0=\"$ip netmask $mask brd $brd\"
routes_eth0=\"default via $routerIP\" """> /etc/conf.d/net

    ;;

  DHCP)
    echo "config_eth0=\"dhcp\""> /etc/conf.d/net
    ;;

  Custom)
    nano /etc/conf.d/net
    ;;

esac

cd /etc/init.d
ln -s net.lo net.eth0
rc-update add net.eth0 default




echo """127.0.0.1	localhost
::1		localhost
127.0.1.1	$hostname.localdomain	$hostname""" > /etc/hosts


echo "Zvolte heslo pro ROOT uživatele"
passwd

#nano /etc/rc.conf		CONFIGURE STARTUP,SERVICES,SHUTDOWN


#nano /etc/conf.d/keymaps	for Keyboard


#nano /etc/conf.d/hwclock 	NEJAKE HODINY IDK    If the hardware clock is not using UTC, then it is necessary to set clock="local" in the file. 
echo "Přidat SystemLogger?: "
select syslog in "Yes" "No";
	break
done
if [ "$syslog"="Yes" ];then
	emerge --ask app-admin/sysklogd
	rc-update add sysklogd default
else
break

echo "Přidat cronie?: "
select cronie in "Yes" "No";
	break
done 
if [ "$cronie"="Yes" ];then
	emerge --ask sys-process/cronie
	rc-update add cronie default
else
break

echo "Zapnout SSH?: "
select ssh in "Yes" "No";
	break
if [ "$ssh"="Yes" ];then
	rc-update add sshd default
else 
break


###########################################################
#							  #
# Uncomment the serial console section in /etc/inittab:   #
# root #nano -w /etc/inittab				  #
#							  #
# # SERIAL CONSOLES					  #
# s0:12345:respawn:/sbin/agetty 9600 ttyS0 vt100	  #
# s1:12345:respawn:/sbin/agetty 9600 ttyS1 vt100	  #
###########################################################



emerge --ask app-shells/bash-completion

emerge --ask net-misc/chrony
rc-update add chronyd default


if [ "$filesystem"="XFS" ];then
	emerge sys-fs/xfsprogs
else
	emerge sys-fs/btrfs-progs
break

emerge sys-fs/dosfstools


emerge --ask sys-block/io-scheduler-udev-rules


#DHCP daemon + Wireless Tools

emerge --ask net-misc/dhcpcd
emerge --ask net-wireless/iw net-wireless/wpa_supplicant

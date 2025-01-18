#! /bin/bash
clear



#sleep 1.5
echo "Instalator vytvoří 3 oddíly na Vašem disku"

#sleep 1.5

echo "Vyberte cílový disk:"
select diskname in /dev/*; do
    if [[ -n $diskname ]]; then
        echo "Zvolen: $diskname"
        break
    else
        echo "Další pokus."
    fi
done

diskname1=${diskname}1
diskname2=${diskname}2
diskname3=${diskname}3

swapsize=$(sudo cat /proc/meminfo | head -n 1 | sed 's/[^0-9]//g')
swapsize=$(($swapsize/1000000))
ramsize=$swapsize
swapsize=$(($swapsize*3/2))


swapsize="+"$swapsize"G"
echo $swapsize;





#cleaning
sudo umount $diskname
sudo umount $diskname1
sudo swapoff $diskname2
sudo wipefs -a $diskname2
sudo umount $diskname3
sudo fdisk "$diskname" <<-RBB
g
w
RBB





sudo fdisk "$diskname" <<- BRR
g
n
1

+1G
t
1
n
2

$swapsize
t
2
19
n
3


t
3
23
w
BRR
echo "Oddíly vytvořeny pro $diskname"



echo "Vyberte souborový systém pro váš Kořenový oddíl"
select filesystem in "xfs" "btrfs" "ext4";
do 
	echo "Formátuji na $filesystem..."
	break
done 2>&1




 
sudo mkfs.vfat -I -F 32 $diskname1

sudo mkfs.$filesystem -f $diskname3

sudo mkswap $diskname2
sudo swapon $diskname2


sudo mkdir --parents /mnt/gentoo
sudo mkdir --parents /mnt/gentoo/efi


sudo mount $diskname3 /mnt/gentoo




cd /mnt/gentoo
sudo chronyd -q


read -p "Zadejte URL Adresu Stage3 Tarballu (Prázdné pro automatické stažení[DESKTOP])" stage3 2>&1		#This downloads "core" Gentoo

if [ -z "$stage3" ]; then
	sudo wget https://ftp.fi.muni.cz/pub/linux/gentoo/releases/amd64/autobuilds/20250115T221822Z/stage3-amd64-desktop-openrc-20250115T221822Z.tar.xz
	echo "Základní"
else
	sudo wget $stage3
	echo "Vlastní"
fi




sudo tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner



echo "Konfigurace CFlags a CXXFlags..." #CFlags and CXXFlags serve as a tool to optimize GCC and C++ compilers
#sleep 1.5


sudo touch /mnt/gentoo/etc/portage/make.conf

sudo echo """# Compiler flags to set for all languages
COMMON_FLAGS=\"-march=native -O2 -pipe\"
# Use the same settings for both variables
CFLAGS=\"${COMMON_FLAGS}\"
CXXFLAGS=\"${COMMON_FLAGS}\"""" | sudo tee /mnt/gentoo/etc/portage/make.conf > /dev/null
echo "Architecture: Native; Optimization O2; Piping Allowed"

########################	ZJIŠŤOVÁNÍ VLÁKEN SYSTÉMU
hreads="$(nproc)"
threads=$((threads+1))
########################


########################	ZJIŠŤOVÁNÍ OPERAČNÍ PAMĚTI
halfram=$(sudo cat /proc/meminfo | head -n 1 | sed 's/[^0-9]//g')
halfram=$((($halfram/1000000)+2))
########################


sudo echo "MAKEOPTS=\"-j$halfram -l$threads\"" | sudo tee -a /mnt/gentoo/etc/portage/make.conf > /dev/null



#DNS INFO
sudo cp --dereference /etc/resolv.conf /mnt/gentoo/etc/


#this is really boring :)
sudo mount --types proc /proc /mnt/gentoo/proc
sudo mount --rbind /sys /mnt/gentoo/sys
sudo mount --make-rslave /mnt/gentoo/sys
sudo mount --rbind /dev /mnt/gentoo/dev
sudo mount --make-rslave /mnt/gentoo/dev
sudo mount --bind /run /mnt/gentoo/run
sudo mount --make-slave /mnt/gentoo/run 



#změna kořene na nové prostředí
sudo chroot /mnt/gentoo /bin/bash #root directory change
source /etc/profile #using profile
export PS1="(chroot) ${PS1}" #??????


sudo mkdir /efi
mount $diskname1 /efi #/mounting efi partition to /efi directory

emerge-webrsync


emerge --ask --verbose --oneshot app-portage/mirrorselect
mirrorselect -i -o >> /etc/portage/make.conf

emerge --sync


eselect profile list 
read -p "Vyberte číslo Profilu: " ProfileNumber
eselect profile set $ProfileNumber






##CPU FLAGS##
echo "CPU přepínače jsou nastaveny Automaticky"
echo "Umístěny v /etc/portage/package.use/00cpu-flags"
emerge --ask --oneshot app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" | sudo tee -a /etc/portage/package.use/00cpu-flags > /dev/null



##VIDEO_CARDS FLAG##
echo "Konfigurace GPU Flags"
echo "Vyberte výrobce Vaší grafické karty: "
select videocard in "intel" "nvidia" "amdgpu"; #missing nouveau driver option
do
	
	echo "VIDEO_CARDS=\"$videocard\"" >> /etc/portage/make.conf
	echo "VIDEO_CARDS = $videocard"
	break
done 2>&1

echo "ACCEPT_LICENSE=\"*\"" | sudo tee -a /etc/portage/make.conf > /dev/null



emerge --ask --verbose --update --deep --newuse @world



emerge --ask --depclean

#OpenRC Timezones
select continent in $(ls /usr/share/zoneinfo);
select country in $(ls /usr/share/zoneinfo/Europe/); 
echo "${continent}/${country}" | sudo tee /etc/timezone > /dev/null

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
echo "sys-kernel/installkernel grub" | sudo tee -a /etc/portage/package.use/installkernel > /dev/null
emerge --ask sys-kernel/installkernel



##InitRamFS
echo "sys-kernel/installkernel dracut" | sudo tee -a /etc/portage/package.use/installkernel > /dev/null


#########################
##KERNEL CONFIG+COMPILE##
#########################

###DISTRIBUTION KERNELS###
echo "Kompilace Jádra: "
select binsrc in "Kompilovat lokálně" "Použít předkompilovaný";
break
done
	

###############

if [ "$binsrc" = "Kompilovat lokálně" ];then
	emerge --ask sys-kernel/gentoo-kernel
else
	emerge --ask sys-kernel/gentoo-kernel-bin #binary??? ew :/
fi

################



##fstab##


echo """
/dev/sda1   /efi         vfat   	umask=0077     		0 2
/dev/sda2   none         swap   	sw                      0 0
/dev/sda3   /            $filesystem    defaults,noatime        0 1
/dev/cdrom  /mnt/cdrom   auto    	noauto,user             0 0""" | sudo tee -a /etc/fstab > /dev/null


##Network##
echo "|Konfigurace sítě|"
select customname in "Vlastní hostname" "Náhodný hostname";
if [ "$customname" = "Vlastní hostname" ]; then
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

  Statická)
    read -p "IP: " ip
    read -p "Maska: " mask
    read -p "Broadcast: " brd  #brdcal
    read -p "Výchozí brána: " routerIP
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



###################################################################################################################################################
#nano /etc/rc.conf		CONFIGURE STARTUP,SERVICES,SHUTDOWN
#nano /etc/conf.d/keymaps	for Keyboard
#nano /etc/conf.d/hwclock 	NEJAKE HODINY IDK    If the hardware clock is not using UTC, then it is necessary to set clock="local" in the file. 
###################################################################################################################################################


#SYSLOGD
echo "Přidat SystemLogger?: "
select syslog in "Ano" "Ne";
	break
done
if [ "$syslog"="Ano" ];then
	emerge --ask app-admin/sysklogd
	rc-update add sysklogd default
else
break


#CRONIE
echo "Přidat cronie?: "
select cronie in "Ano" "Ne";
	break
done
if [ "$cronie"="Ano" ];then
	emerge --ask sys-process/cronie
	rc-update add cronie default
else
break


#SSH
echo "Zapnout SSH?: "
select ssh in "Ano" "Ne";
	break
if [ "$ssh"="Ano" ];then
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



#BOOTLOADER
echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
emerge --ask sys-boot/grub
grub-install --efi-directory=/efi
grub-mkconfig -o /boot/grub/grub.cfg




exit
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo

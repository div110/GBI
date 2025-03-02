source /etc/profile #using profile
export PS1="(chroot) ${PS1}" #??????

diskname1=$(cat diskname1)
diskname2=$(cat diskname2)
diskname3=$(cat diskname3)
filesystem=$(cat filesystem)
mkdir /efi
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
echo "*/* $(cpuid2cpuflags)" | tee -a /etc/portage/package.use/00cpu-flags > /dev/null



##VIDEO_CARDS FLAG##
echo "Konfigurace GPU Flags"
echo "Vyberte výrobce Vaší grafické karty: "
select videocard in "intel" "nvidia" "amdgpu"; #missing nouveau driver option
do
	
	echo "VIDEO_CARDS=\"$videocard\"" | tee -a /etc/portage/make.conf > /dev/null
	echo "VIDEO_CARDS = $videocard"
	break
done 2>&1

echo "ACCEPT_LICENSE=\"*\"" | tee -a /etc/portage/make.conf > /dev/null



emerge --ask --verbose --update --deep --newuse @world



emerge --ask --depclean

#OpenRC Timezones
select continent in /usr/share/zoneinfo/*;do
break
done
echo $continent
select country in $continent/*;do
break
done
echo ${country} | sed 's/\S*info\///g' | tee /etc/timezone > /dev/null


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
echo "sys-kernel/installkernel grub" | tee -a /etc/portage/package.use/installkernel > /dev/null
emerge --ask sys-kernel/installkernel



##InitRamFS
echo "sys-kernel/installkernel dracut" | tee -a /etc/portage/package.use/installkernel > /dev/null


#########################
##KERNEL CONFIG+COMPILE##
#########################

###DISTRIBUTION KERNELS###
echo "Kompilace Jádra: "
select binsrc in "Kompilovat lokálně" "Použít předkompilovaný";do
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
$diskname1   /efi         vfat   	umask=0077     		0 2
$diskname2   none         swap   	sw                      0 0
$diskname3   /            $filesystem    defaults,noatime        0 1
/dev/cdrom  /mnt/cdrom   auto    	noauto,user             0 0""" | tee -a /etc/fstab > /dev/null


##Network##
#aby dhcp nekazil
chattr +i /etc/resolv.conf

echo "|Konfigurace sítě|"
select customname in "Vlastní hostname" "Náhodný hostname";do
break
done
if [ "$customname" = "Vlastní hostname" ]; then
	read -p "Enter hostname: " hostname
else
	hostname=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 6)
 	echo $hostname
fi


echo $hostname | tee /etc/hostname > /dev/null
emerge --ask net-misc/dhcpcd
rc-update add dhcpcd default
rc-service dhcpcd start


emerge --ask --noreplace net-misc/netifrc 

ip link show | awk -F': ' '/^[0-9]+: / {print $2}'
read -p "Write interface you want to configure :" iface
echo $iface

select ipconfig in "Statická" "DHCP" "nano";do
break
done
case $ipconfig in

  Statická)
    read -p "IP: " ip
    read -p "Maska: " mask
    read -p "Broadcast: " brd  #brdcal
    read -p "Výchozí brána: " routerIP
    echo """config_$iface=\"$ip netmask $mask brd $brd\"
routes_$iface=\"default via $routerIP\" """ | tee /etc/conf.d/net

    ;;

  DHCP)
    echo "config_$iface=\"dhcp\"" | tee /etc/conf.d/net
    ;;

  nano)
    nano /etc/conf.d/net
    ;;

esac

cd /etc/init.d
#ln -s net.lo net.eth0
rc-update add net default




echo """127.0.0.1	localhost
::1		localhost
127.0.0.1	$hostname.localdomain	$hostname""" | tee -a /etc/hosts


echo "Zvolte heslo pro ROOT uživatele"
passwd



###################################################################################################################################################
#nano /etc/rc.conf		CONFIGURE STARTUP,SERVICES,SHUTDOWN
#nano /etc/conf.d/keymaps	for Keyboard
#nano /etc/conf.d/hwclock 	NEJAKE HODINY IDK    If the hardware clock is not using UTC, then it is necessary to set clock="local" in the file. 
###################################################################################################################################################


#SYSLOGD
echo "Přidat SystemLogger?: "
select syslog in "Ano" "Ne";do
        echo $syslog
        break
done

if [ "$syslog" = "Ano" ];then
        
        emerge --ask app-admin/sysklogd
        rc-update add sysklogd default
fi


#CRONIE
echo "Přidat cronie?: "
select cronie in "Ano" "Ne";do
	break
done
if [ "$cronie" = "Ano" ];then
	emerge --ask sys-process/cronie
	rc-update add cronie default
fi


#SSH
echo "Zapnout SSH?: "
select ssh in "Ano" "Ne";do
	break
 done
if [ "$ssh"="Ano" ];then
	rc-update add sshd default
fi


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


if [ "$filesystem"="xfs" ];then
	emerge sys-fs/xfsprogs
else
	emerge sys-fs/btrfs-progs
fi


emerge sys-fs/dosfstools
emerge --ask sys-block/io-scheduler-udev-rules


#DHCP daemon + Wireless Tools
emerge --ask net-misc/dhcpcd
emerge --ask net-wireless/iw net-wireless/wpa_supplicant



#BOOTLOADER
#restarted, got into chroot + ?REMOUNTED?
#something not right
#manual fix:
#grub-install --efi-directory=/efi
#grub-mkconfig -o /boot/grub/grub.cfg
#
echo 'GRUB_PLATFORMS="efi-64"' | tee -a /etc/portage/make.conf
emerge --ask sys-boot/grub
grub-install --efi-directory=/efi
grub-mkconfig -o /boot/grub/grub.cfg




exit
cd
sudo umount -l /mnt/gentoo/dev{/shm,/pts,}
sudo umount -R /mnt/gentoo

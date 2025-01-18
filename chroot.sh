source /etc/profile #using profile
export PS1="(chroot) ${PS1}" #??????


sudo mkdir /efi
sudo mount $diskname1 /efi #/mounting efi partition to /efi directory

sudo emerge-webrsync


sudo emerge --ask --verbose --oneshot app-portage/mirrorselect
sudo mirrorselect -i -o >> /etc/portage/make.conf

sudo emerge --sync


eselect profile list 
read -p "Vyberte číslo Profilu: " ProfileNumber
sudo eselect profile set $ProfileNumber






##CPU FLAGS##
echo "CPU přepínače jsou nastaveny Automaticky"
echo "Umístěny v /etc/portage/package.use/00cpu-flags"
sudo emerge --ask --oneshot app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" | sudo tee -a /etc/portage/package.use/00cpu-flags > /dev/null



##VIDEO_CARDS FLAG##
echo "Konfigurace GPU Flags"
echo "Vyberte výrobce Vaší grafické karty: "
select videocard in "intel" "nvidia" "amdgpu"; #missing nouveau driver option
do
	
	echo "VIDEO_CARDS=\"$videocard\"" | sudo tee -a /etc/portage/make.conf > /dev/null
	echo "VIDEO_CARDS = $videocard"
	break
done 2>&1

echo "ACCEPT_LICENSE=\"*\"" | sudo tee -a /etc/portage/make.conf > /dev/null



sudo emerge --ask --verbose --update --deep --newuse @world



sudo emerge --ask --depclean

#OpenRC Timezones
select continent in /usr/share/zoneinfo/*;do
break
done
echo $continent
select country in $continent/*;do
break
done
echo ${country} | sed 's/\S*info\///g' | sudo tee /etc/timezone > /dev/null


sudo emerge --config sys-libs/timezone-data


select locale in $(cat /usr/share/i18n/SUPPORTED);
do
	echo "		<====>"
	locale-gen
	break
done 2>&1


sudo eselect locale list
read locale
sudo eselect locale set $locale

sudo env-update && source /etc/profile && export PS1="(chroot) ${PS1}"


sudo emerge --ask sys-kernel/linux-firmware

sudo emerge --ask sys-firmware/sof-firmware #to be safe
sudo emerge --ask sys-firmware/intel-microcode #Just for Intel CPUs

##Bootloader##
#just GRUB for now

sudo touch /etc/portage/package.use/installkernel
echo "sys-kernel/installkernel grub" | sudo tee -a /etc/portage/package.use/installkernel > /dev/null
sudo emerge --ask sys-kernel/installkernel



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
	sudo emerge --ask sys-kernel/gentoo-kernel
else
	sudo emerge --ask sys-kernel/gentoo-kernel-bin #binary??? ew :/
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
 	cat $hostname
fi


echo $hostname | sudo tee /etc/hostname > /dev/null
sudo emerge --ask net-misc/dhcpcd
sudo rc-update add dhcpcd default
sudo rc-service dhcpcd start


sudo emerge --ask --noreplace net-misc/netifrc 

select ipconfig in "Statická" "DHCP" "Custom";
case $ipconfig in

  Statická)
    read -p "IP: " ip
    read -p "Maska: " mask
    read -p "Broadcast: " brd  #brdcal
    read -p "Výchozí brána: " routerIP
    echo """config_eth0=\"$ip netmask $mask brd $brd\"
routes_eth0=\"default via $routerIP\" """ | sudo tee /etc/conf.d/net

    ;;

  DHCP)
    echo "config_eth0=\"dhcp\"" | sudo tee /etc/conf.d/net
    ;;

  Custom)
    sudo nano /etc/conf.d/net
    ;;

esac

cd /etc/init.d
ln -s net.lo net.eth0
sudo rc-update add net.eth0 default




echo """127.0.0.1	localhost
::1		localhost
127.0.1.1	$hostname.localdomain	$hostname""" | sudo tee -a /etc/hosts


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
	sudo emerge --ask app-admin/sysklogd
	sudo rc-update add sysklogd default
else
break


#CRONIE
echo "Přidat cronie?: "
select cronie in "Ano" "Ne";
	break
done
if [ "$cronie"="Ano" ];then
	sudo emerge --ask sys-process/cronie
	sudo rc-update add cronie default
else
break


#SSH
echo "Zapnout SSH?: "
select ssh in "Ano" "Ne";
	break
if [ "$ssh"="Ano" ];then
	sudo rc-update add sshd default
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



sudo emerge --ask app-shells/bash-completion
sudo emerge --ask net-misc/chrony
sudo rc-update add chronyd default


if [ "$filesystem"="XFS" ];then
	sudo emerge sys-fs/xfsprogs
else
	sudo emerge sys-fs/btrfs-progs
break


sudo emerge sys-fs/dosfstools
sudo emerge --ask sys-block/io-scheduler-udev-rules


#DHCP daemon + Wireless Tools
sudo emerge --ask net-misc/dhcpcd
sudo emerge --ask net-wireless/iw net-wireless/wpa_supplicant



#BOOTLOADER
echo 'GRUB_PLATFORMS="efi-64"' | sudo tee -a /etc/portage/make.conf
sudo emerge --ask sys-boot/grub
sudo grub-install --efi-directory=/efi
sudo grub-mkconfig -o /boot/grub/grub.cfg




exit
cd
sudo umount -l /mnt/gentoo/dev{/shm,/pts,}
sudo umount -R /mnt/gentoo

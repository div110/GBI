#! /bin/bash
clear

sudo chmod +x chroot.sh
sudo cp chroot.sh /chroot.sh


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



chmod +x chroot.sh
mv chroot.sh /mnt/gentoo
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
CFLAGS=\"-march=native -O2 -pipe\"
CXXFLAGS=\"-march=native -O2 -pipe\"""" | sudo tee /mnt/gentoo/etc/portage/make.conf > /dev/null
echo "Architecture: Native; Optimization O2; Piping Allowed"

########################	ZJIŠŤOVÁNÍ VLÁKEN SYSTÉMU
threads="$(nproc)"
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


sudo mv /chroot.sh /mnt/gentoo/chroot.sh
#změna kořene na nové prostředí
sudo chroot /mnt/gentoo /bin/bash

clear
echo "the Installer will create 3 Partitions on your Disk"
sleep 1.5
echo "PLEASE SELECT YOUR DISK"

cd /dev/
select diskname in *;

do
	echo "Selecting $diskname..."
	break;
done

fdisk /dev/nvme0n1

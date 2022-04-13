#!/bin/env bash
#set -x

export LANG="en_US.UTF-8"
export LANGUAGE="en_US"

disk_path=""
chroot_path="/mnt"
# 控制日志等级
echo "4 4 1 7" > /proc/sys/kernel/printk

umount_disk(){
	df |grep "$1" |awk '{print  $1}' |xargs umount -l
	# 另一种方法
	# echo "umount disk" "$1"
	# umount "$1"* &>/dev/null
}

findRootfs(){
rootfs_path=""
disk_path="$1"
if [ "$2" != "" ] ;then
	if  [ -f $(realpath "$2") ];then
		rootfs_path=$(realpath "$2")
		echo "get file" "$rootfs_path" 
	else
		echo "want a file"
	fi
elif [ -f /run/live/medium/rootfs.img ];then
	rootfs_path="/run/live/medium/rootfs.img"
else
	if [ -f /rootfs.img ];then
		rootfs_path="/rootfs.img"
	else
		echo "Error /rootfs.img lost"
		exit 2
	fi	
fi
umount_disk "$disk_path"
echo "Install OS, please wait..."
ddRootfs "$rootfs_path" "$disk_path"
echo "dd done"
}

ddRootfs(){
	rootfs_path="$1"
	disk_path="$2"
	#rootfs_size=$(du -m "$rootfs_path"|awk  '{print $1}')
	#for ((i=0;i<="$rootfs_size";i+=500))
	#do
	#	dd if="$rootfs_path" of="$disk_path" bs=1M count=500 skip="$i" seek="$i"
	#	echo "$i" doing
	#	echo 3 > /proc/sys/vm/drop_caches
	#	# sleep 1
	#done
	echo "start dd"
	# the code from shijiayu
	if mount | awk '{print $3, $5}' | grep -sq '^/ nfs'; then
        echo "in_nfs"
        file_size=$(stat -c %s "$rootfs_path")
        dd_once_size=$((1024*1024*100))
        last_block_start=$((file_size-dd_once_size))
        for ((i=0;i<="$file_size";i+="$dd_once_size")) {
            COUNT=""
            if [ $i -le $last_block_start ];then
                COUNT="count=100"
            fi
            ((dd_start=i/(1024*1024)))
            dd if="$rootfs_path" of="$disk_path" bs=1M seek=$dd_start skip=$dd_start  $COUNT &> /dev/null
            echo 3 > /proc/sys/vm/drop_caches &> /dev/null
        }
    else
        echo "local install"
        dd if="$rootfs_path" of="$disk_path" bs=1M &> /dev/null
    fi
	sync
    partprobe
    sleep 2
	# 防自动挂载
	umount_disk "$disk_path"

	echo "done"
}

updateDisk(){
	echo "Update disk part..."

	part1_end=$(parted "$1"1 unit mb print |grep "Disk ${1}1"|awk '{print $3}'| sed "s|MB||g")
	part2_start=$(("$part1_end + 1"))
	part2_end=$(("$part2_start + 2048"))
	part3_start=$(("$part2_end" + 1))
	parted -s "$1" mkpart primary linux-swap   "$part2_start"M "$part2_end"M
	mkswap  "$1"2
	
	parted -s "$1" mkpart primary ext4  "$part3_start"M 100%
	wipefs -a "$1"3
	mkfs.ext4  "$1"3
	#e2fsck -f "$1"
	#e2fsck -yf "$1"2
	
	# 防自动挂载
	sync
    partprobe
    sleep 2
    umount_disk "$disk_path"
}


mount_disk(){
	echo "mount disk" "$1"
	mount "$1"1 $chroot_path
}




mount_dir(){
    mount -t devtmpfs udev "$chroot_path"/dev
    mount -t devpts devpts "$chroot_path"/dev/pts
    mount -t sysfs sys "$chroot_path"/sys
    mount -t proc proc "$chroot_path"/proc
}

umount_dir(){
	umount "$chroot_path"/dev/pts
    umount "$chroot_path"/dev
    umount "$chroot_path"/sys
    umount "$chroot_path"/proc
}

# 此为后门暂不可用
do_hooks(){
	if [ -d ./hooks ];then
		cp -rv ./hooks /mnt/
	elif [ -d /hooks ];then
		cp -rv /hooks "$chroot_path"
	
	elif [ -d /run/live/medium/hooks ];then
		cp -rv /run/live/medium/hooks "$chroot_path"
	else
        echo "nothing to do in chroot"
        return 0
    fi

	mount_dir

    if [ -d "$chroot_path"/hooks/deb ];then
        echo "start install deb chroot"
        chroot "$chroot_path" /bin/bash -c "dpkg -i hooks/deb/*.deb"
    else
        echo "no othre deb install in chroot"
    fi

	if [ -d "$chroot_path"/hooks/kernel ];then
        echo "start install deb chroot"
		chroot "$chroot_path" /bin/bash -c "dpkg -l |grep linux-image |awk '{print \$2}'|xargs apt purge -y"
        rm -rf "$chroot_path"/boot/boot.cfg
		chroot "$chroot_path" /bin/bash -c "dpkg -i hooks/kernel/*.deb;update-grub"
    else
        echo "no othre deb install in chroot"
    fi	

    if [ -f "$chroot_path"/hooks/hooks.sh ];then
        echo "start do in chroot"
        chroot "$chroot_path" /hooks/hooks.sh 
    else
        echo " no hooks scripts in chroot"
    fi

	umount_dir
}

choice_tty(){
while true
do
	if [ ! -f "$chroot_path"/boot/boot.cfg ];then
		return 1
	fi
	read -rp "Which tty you want to boot ? (Example :ttyS0) :" tty_path
	echo "$tty_path"
	if [ -z "$tty_path" ];then
		echo "value is nil, please input again"
		continue
	fi
	if [[ "$tty_path" == *"tty"* ]];then
		echo "Will boot form" "$tty_path"
		sed -i "s|console=ttyS0|console=$tty_path|g" "$chroot_path"/boot/boot.cfg
		break
	else
		echo "value is worng, please input again"
		continue
	fi

	
done
}

update_ssh(){
	if [ ! -f "$chroot_path"/etc/ssh/sshd_config ];then
		echo "no ssh conf to update"
		return 1
	else
		sed -i '/PermitRootLogin/d' "$chroot_path"/etc/ssh/sshd_config
		echo "PermitRootLogin yes" >> "$chroot_path"/etc/ssh/sshd_config
	fi
}

update_fstab(){
	if [ ! -f "$chroot_path"/etc/fstab ];then
		echo "no fstab conf to update"
		return 1
	else
echo "# UNCONFIGURED FSTAB FOR BASE SYSTEM
/dev/sda1 / ext3 rw,relatime 0 1
/dev/sda2 none swap sw 0 0
/dev/sda3 /work ext4 rw,relatime 0 1" > "$chroot_path"/etc/fstab
	mkdir -p "$chroot_path"/work

	fi
}

user_check(){
    
    if [ "$USER" != "root" ];then
        echo "please use root user !"
        exit 1
    fi
}

main(){

user_check

echo "Welcome,Now we will install system"
echo "!!!Please check you are root. Please don't use sudo!!!"
echo "Please check which disk you want to install"

lsblk

while true
do
read -rp "Which disk you want to install ? (Please input full disk path, Example:/dev/sda) :" disk_path
echo "${disk_path}"
if [ "$disk_path" == "exit" ];then
	exit 1
fi

if [ -z "${disk_path}" ];then
	echo "value is nil, please input again"
	continue
fi

lsblk "${disk_path}"
if lsblk "${disk_path}" ;then
	break
fi
done

findRootfs "${disk_path}" "$1"

updateDisk "${disk_path}"

mount_disk "${disk_path}"

update_ssh

update_fstab

# do_hooks

# choice_tty

umount_disk "$disk_path"

}

main "$@"

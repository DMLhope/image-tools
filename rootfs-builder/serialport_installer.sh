#!/bin/env bash
#set -x

export LANG="en_US.UTF-8"
export LANGUAGE="en_US"

disk_path=""
chroot_path="/mnt"

umount_disk(){
	 df |grep "$1" |awk '{print  $1}' |xargs umount -l
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
ddRootfs "$rootfs_path" "$disk_path"
echo "Please wait..."
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
	dd if="$rootfs_path" of="$disk_path" bs=1M 
	echo 3 >  /proc/sys/vm/drop_caches
	echo "done"
}

updateDisk(){
	echo "Update disk part..."
	part1_end=$(parted "$1"1 unit mb print |grep "Disk ${1}1"|awk '{print $3}'| sed "s|MB||g")
	part2_start=$(("$part1_end + 1"))
	part2_end=$(("$part2_start + 2048"))
	part3_start=$(("$part2_end" + 1))
	#parted -s "$1" mkpart primary linux-swap   "$part2_start"M "$part2_end"M
	#mkswap  "$1"2
	
	parted -s "$1" mkpart primary ext4  "$part2_start"M 100%
	wipefs -a "$1"2
	mkfs.ext4  "$1"2
	#e2fsck -f "$1"
	#e2fsck -yf "$1"2
}


mount_disk(){
	echo "mount disk" "$1"
	mount "$1"1 /mnt
}

umount_disk(){
	echo "umount disk" "$1"
	umount "$1"1
}

# updateUuid(){
# 	echo "Update UUID ..."
# 	tune2fs -U 46c9df11-afc8-452a-855a-3d11b8ff1d31 "$1"1
# }

mount_dir(){
    mount --bind /dev "$chroot_path"/dev
    mount -t sysfs sys "$chroot_path"/sys
    mount -t proc proc "$chroot_path"/proc
}

umount_dir(){
    umount "$chroot_path"/dev
    umount "$chroot_path"/sys
    umount "$chroot_path"/proc
}

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
        echo "update fstab configure"
        if [ ! -f "$chroot_path"/etc/fstab ];then
                echo "no fstab conf to update"
                return 1
        else
                root_uuid=`blkid ${disk_path}1 | awk '{print $2}'`
                work_uuid=`blkid ${disk_path}2 | awk '{print $2}'`
                echo "# UNCONFIGURED FSTAB FOR BASE SYSTEM
${root_uuid} / ext3 rw,relatime 0 1
${work_uuid} /work ext4 rw,relatime 0 1" > "$chroot_path"/etc/fstab
        fi
}



update_kernel(){
  cp -v "$chroot_path"/boot/initrd* "$chroot_path"/boot/initrd.img
  cp -v "$chroot_path"/boot/vmlinu* "$chroot_path"/boot/vmlinuz
}

update_vsftpd(){
	if [ ! -f "$chroot_path"/etc/vsftpd.conf ];then
		echo "no vsftpd conf to update"
		return 1
	else
		sed -i '/local_root=/d' "$chroot_path"/etc/vsftpd.conf

		echo "local_root=/work/" >> "$chroot_path"/etc/vsftpd.conf

		sed -i "s|xferlog_enable=.*|#xferlog_enable=YES|g" "$chroot_path"/etc/vsftpd.conf
	fi
}

update_bashrc(){
	echo "if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi" >> "$chroot_path"/root/.bashrc
}

update_vimrc(){
	echo "set viminfo='50,<1000,s100,:0,n~/work/.viminfo'" >>  "$chroot_path"/root/.vimrc
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

update_vsftpd	

update_bashrc

update_vimrc

update_kernel

do_hooks

choice_tty

umount_disk "$disk_path"

}

main "$@"

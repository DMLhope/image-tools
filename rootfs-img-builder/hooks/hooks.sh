#!/usr/bin/env bash
#hooks.sh

add_repo(){
  echo "" >> /etc/apt/sources.list
  apt update
}


apt_install() {
  DEBIAN_FRONTEND="noninteractive" apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"  --allow-unauthenticated install "$@"
}

install_pkg(){
  apt_install  bash-completion openssl sudo vim locales-all locales openssh-server pciutils 
  if [ -f /package.list/extra_deb.list ];then
    extra_deb=$(xargs --arg-file=/package.list/extra_deb.list)
    # 这里打死不能写成apt_install ”$kernel_deb“ ”$extra_deb“ 会被转义成带单引号的变量从而无法安装
    apt_install $extra_deb
  else
    echo "no packagelist will install"
  fi
}


update_ssh(){
	if [ ! -f /etc/ssh/sshd_config ];then
		echo "no ssh conf to update"
		return 1
	else
		sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
		echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
	fi
}

change_root_passwd(){
  echo root:123 |chpasswd
}


add_user(){
  useradd -m -G sudo -s  /bin/bash -p "$(openssl passwd -1 fxos)" fxos
}

set_hostname(){
  echo "fxos-pc" > /etc/hostname
}

set_rclocal(){
  touch /.resize_done
  cat > /etc/rc.local <<EOF
#!/bin/bash -e
# 检查标志文件是否存在
if [ -f /.resize_done ]; then
    resize2fs /dev/mmcblk0p3
    rm -f /.resize_done
fi
exit 0
EOF
  chmod +x /etc/rc.local
}

set_osversion(){
  cat > /etc/os-release <<EOF
PRETTY_NAME="FXOS"
NAME="FXOS"
VERSION_ID="1"
VERSION="1"
VERSION_CODENAME=bookworm
ID=fxos
HOME_URL="https://feixianos.com"
SUPPORT_URL="https://feixianos.com"
BUG_REPORT_URL="https://feixianos.com"
EOF
  cat > /etc/lsb-release <<EOF
DISTRIB_ID=fxos
DISTRIB_RELEASE=1
DISTRIB_CODENAME=bookworm
DISTRIB_DESCRIPTION="FXOS"
EOF
  cat > /etc/debian_version <<EOF
12.2
EOF
  cat > /etc/os-version <<EOF
1.0
EOF
  cat > /etc/issue <<EOF
FXOS GNU/Linux 1.0 \n \l
EOF
  cat > /etc/issue.net <<EOF
FXOS GNU/Linux 1.0
EOF
}

set_motd(){
  cat > /etc/motd <<EOF
  
  ███████╗██╗  ██╗ ██████╗ ███████╗
  ██╔════╝╚██╗██╔╝██╔═══██╗██╔════╝
  █████╗   ╚███╔╝ ██║   ██║███████╗
  ██╔══╝   ██╔██╗ ██║   ██║╚════██║
  ██║     ██╔╝ ██╗╚██████╔╝███████║
  ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
  Homepage:  https://feixianos.com

EOF
}

main(){
  add_repo
  # set_hosts
  install_pkg
  change_root_passwd
  add_user
  set_hostname
  update_ssh
  set_rclocal
  set_motd
  set_osversion
  # clean_hosts
}

main

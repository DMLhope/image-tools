#!/bin/bash
packagelist_path="/uos-installer/package.list"
install_package() {
#  DEBIAN_FRONTEND="noninteractive" apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --no-install-recommends --allow-unauthenticated install $@
  for i in $@;
  do
    DEBIAN_FRONTEND="noninteractive" apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --no-install-recommends --allow-unauthenticated install $i
    if [ $? -eq 0 ]; then
      echo "succeed"
    else
      echo "Install Failed : $i"
    fi
  done
}

main(){
    apt update || echo "apt update error"
    if [ -f $packagelist_path ];then
    package_list=$(xargs --arg-file="$packagelist_path")
    # 这里打死不能写成"$···" 会被转义成带单引号的变量从而无法安装
    install_package $package_list
    fi
}
main
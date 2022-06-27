#!/bin/bash
set -x

mount_path=""

opts_check(){
            if [[ $# != 1 ]];then
                            echo "请接上被挂载目录的路径作为参数"
                                    exit 2
                                        fi
                                            if [ ! -d $1 ];then
                                                            echo "请确认参数是被挂载的目录"
                                                                    exit 3
                                                                        fi
                                                                }
                                                        user_check(){  
                                                                    if [ "$USER" != "root" ];then
                                                                                    echo "please use root user or sudo !"
                                                                                            exit 1
                                                                                                fi
                                                                                        }

                                                                                umount_rootfs(){
                                                                                            umount -l "$mount_path"/dev/pts/
                                                                                                umount -l "$mount_path"/dev
                                                                                                    umount -l "$mount_path"/proc/
                                                                                                        umount -l "$mount_path"/sys/
                                                                                                            devicepart_path=$(df |grep "$mount_path"|awk '{print $1}')
                                                                                                                umount -l "$devicepart_path"
                                                                                                                    device_path=$(echo $devicepart_path |sed "s|p1$||g")
                                                                                                                        losetup -d "$device_path"
                                                                                                                }

                                                                                                        main(){
                                                                                                                    opts_check "$@"
                                                                                                                        user_check
                                                                                                                            mount_path=$(realpath "$1")
                                                                                                                                umount_rootfs
                                                                                                                        }

                                                                                                                main "$@"

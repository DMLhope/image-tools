## 使用参考
1. 请在当前目录执行
2. 请用root或sudo执行
3. 第一个参数为squashfs路径
4. 第二个参数为安装到的硬盘路径

例如：
```
sudo ./main.sh ~/filesystem.squashfs /dev/sdb
```

##  目录结构
脚本代码应该被安装在 `/usr/share/uos-installer/hooks` 目录
```
hooks
├── auto-part
│   ├── auto_part.sh
│   ├── create_fstab.sh
│   ├── mount_target.sh
│   ├── test.json
│   └── umount_target.sh
├── before_chroot
│   ├── before_chroot.sh
│   ├── set_repo.sh
│   └── un_squashfs.sh
├── conf.json
├── in_chroot
│   ├── in_chroot.sh
│   ├── install_package.sh
│   ├── setup_bootloader.sh
│   ├── setup_keyboard.sh
│   ├── setup_lightdm.sh
│   ├── setup_locale.sh
│   ├── setup_timezone.sh
│   └── setup_user.sh
├── main.sh
├── README.md
└── tools
    ├── mount_chroot.sh
    └── umount_chroot.sh
```
## 所需配置文件路径
1. 分区配置文件 `/uos-installer/parted.json`
2. 用户设置配置文件 `/uos-installer/installer_settings.json`
3. packagelist位置 `/uos-installer/package.list`

## 应该固定的文件位置
1. filesystem.squashfs位置

## 流程
由安装器主程序调用main.sh

main.sh接收两个参数
1. filesystem.squashfs路径
2. 需要安装到的设备，例如`/dev/sda`

main.sh 为脚本调用主程序
首先对脚本目录进行复制，复制到`/installer`目录下
检查配置文件是否正常生成
分区
挂载目录
解压squashfs
做设置



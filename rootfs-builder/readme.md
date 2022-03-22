# 设计

## 主脚本

rootfs-builder.sh

## hooks

hooks目录中可以放

+ hooks-data目录
  + 用来将data自动放到chroot中
+ hooks.sh脚本
  + 用来在chroot中执行的脚本
  
## 流程

+ 确认环境
+ 基于debootstrap拉取文件系统
+ 挂载必要目录
+ 安装需要软件并进行其他操作(hooks)
+ 卸载对应目录
+ 打包squashfs
  
## Example

```bash
# x86_64 debian
sudo ./rootfs-builder.sh stable http://deb.debian.org/debian/
# mips v15
sudo ./rootfs-builder.sh camel http://packages.deepin.com/deepin/
```

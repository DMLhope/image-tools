#!/bin/bash

if [ -d /target/data ];then
    umount /target/opt
    umount /target/var
    umount /target/home
    umount /target/root
    umount /target/data
fi

if [ -d /target/media/cdrom ];then
    umount /target/media/cdrom
fi

if [ -d /target/recovery ];then
    umount /target/recovery
fi

if [ -d /target/boot ];then
    if [ -d /target/boot/efi ];then
        umount /target/boot/efi
    fi
    umount /target/boot
fi

if [ -d /target ];then
    umount /target
fi

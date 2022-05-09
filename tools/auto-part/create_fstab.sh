#!/bin/bash

if [ -f "/tmp/fstab.in" ] && [ -d "/target/etc" ];then
    cp -v /tmp/fstab.in /target/etc/fstab
fi
#!/bin/bash
isomount_path=$1
repo_path=$isomount_path/dists
mkdir -p /target/media/cdrom
mount --bind "$isomount_path" /target/media/cdrom || echo "Failed to bind ${isomount_path}"


if [ -d $repo_path ];then
# commented source.list to let apt-get just using cdrom repo.
sed -i 's/^/#/g' /target/etc/apt/sources.list

dir=$(find  $repo_path -name "Release" | xargs awk -F '[ :]+' '/Codename/{print $2}')
for name in $dir
do
    # ident the cdrom first.
    echo "deb [trusted=yes] file:/media/cdrom ${name} main" >> /target/etc/apt/sources.list
done
fi
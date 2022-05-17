#!/bin/bash

json_path="/conf.json"

check_conf(){
  if [ -n "$1" ] && [ -f "$1" ];then
    declare -g json_path="$1"
  fi
}

msg() {
  local msg="$@"
  echo "Info: ${msg}"
}

enable_local_rtc() {
    # local timezone_use_local_time_regardless timezone_force_local_time
    local DI_IS_LOCAL_TIME
    # timezone_use_local_time_regardless=$(installer_get "timezone_use_local_time_regardless")
    # timezone_force_local_time=$(installer_get "timezone_force_local_time")
    # DI_IS_LOCAL_TIME=$(installer_get "DI_IS_LOCAL_TIME")
    DI_IS_LOCAL_TIME=$(jq -r ".timezone.DI_IS_LOCAL_TIME" $json_path)

    # timezone_use_local_time_regardless = true 时
    # 1. 当 timezone_force_local_time = true 强制禁止UTC时间
    # 2. 当使用windwos系统时间时（timezone_use_windows_time = true），如果检测到windows分区，则
    #   DI_IS_LOCAL_TIME = true  禁止UTC时间
    # if [[ x"${timezone_use_local_time_regardless}" = xtrue &&
    #     (x"${timezone_force_local_time}" = xtrue ||
    #      x"${DI_IS_LOCAL_TIME}" = xtrue) ]]; then
    if [ "${DI_IS_LOCAL_TIME}" = "true" ];then
        timedatectl set-local-rtc 1
    else
        timedatectl set-local-rtc 0
    fi
}

# set timedate
set_timedate() {
    local IS_ENABLE_NTP
    local TIMEDATE
    IS_ENABLE_NTP=$(jq -r ".timezone.DI_IS_ENABLE_NTP" $json_path)
    if [[ x"${IS_ENABLE_NTP}" != xtrue ]]; then

        TIMEDATE=$(jq -r ".timezone.SET_DATE_TIME" $json_path)
    else
        # 1031之后由于系统关机时系统时间会被同步到rtc中，所以在设置时间的时候需要在没有时区干扰的情况下同步rtc时间为系统时间，防止每次安装系统后系统时间+8
        TIMEDATE=$rtc_date
        echo "rtc_date=""$rtc_date"
    fi

    timedatectl set-ntp false  # 先禁止时间同步服务， 防止时间设置不生效
    timedatectl set-time "${TIMEDATE}"
}

enable_ntp() {
    local DI_IS_ENABLE_NTP
    DI_IS_ENABLE_NTP=$(jq -r ".timezone.DI_IS_ENABLE_NTP" $json_path)
    if [[ x"${DI_IS_ENABLE_NTP}" = xtrue ]]; then      
        # 启动ntp服务，设置开启时间同步属性
        rm -fr /usr/lib/systemd/system/systemd-timesyncd.service.d/disable-timesyncd-with-installer.conf
        timedatectl set-ntp true
        msg "timedatectl set-ntp true"
    else
        # 手动设置时间时，关闭ntp服务
        timedatectl set-ntp false
        msg "timedatectl set-ntp false"
    fi
}

# 同步系统时间对rtc中
datetime_hctosys() {
    local timedate_is_sysnc
    # 配置是否将系统时间同步到rtc时间中
    timezone_is_sysnc=$(jq -r ".timezone.timezone_is_sysnc" $json_path)
    if [[ x"${timezone_is_sysnc}" = xtrue ]]; then
        hwclock --systohc
    fi
}

# Setup timezone.
setup_timezone() {
  local DI_TIMEZONE
  DI_TIMEZONE=$(jq -r ".timezone.DI_TIMEZONE"  $json_path)

  DI_TIMEZONE=${DI_TIMEZONE:-Etc/UTC}


  echo "Check timezone ${DI_TIMEZONE}"
  if cat /usr/share/zoneinfo/zone.tab | grep -v '^#' | awk '{print $3}' | \
      grep -q "^${DI_TIMEZONE}$"; then
    msg "${DI_TIMEZONE} is available"
  else
    msg "Timezone is not available, Fall back to Asia/Shanghai"
    DI_TIMEZONE="Asia/Shanghai"
  fi

  # 在没有设置时区之前记录rtc时间，此时系统处于+0时区，系统时间=rtc时间
  rtc_date=$(date "+%Y-%m-%d %H:%M:%S")

  msg "Set timezone to ${DI_TIMEZONE}"
  echo "${DI_TIMEZONE}" > /etc/timezone
  # Create /etc/localtime symbol links
  ln -nsf /usr/share/zoneinfo/${DI_TIMEZONE} /etc/localtime
  dpkg-reconfigure --frontend noninteractive tzdata

  # Set using local time or not
  # TODO 时间设置部分依赖systemd服务，chroot环境中无法正常执行，是否考虑舍弃
  echo "enable_local_rtc"
  enable_local_rtc
  echo "set_timedate"
  set_timedate
  echo "enable_ntp"
  enable_ntp
  echo "datetime_hctosys"
  datetime_hctosys

  touch -c /usr/share/applications/*


  [ -x /usr/sbin/update-grub ] && /usr/sbin/update-grub
}

main(){
  
  check_conf "$@"
  setup_timezone
}

main "$@"
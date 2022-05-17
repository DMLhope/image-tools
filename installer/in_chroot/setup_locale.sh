#!/bin/bash

CONF_SETTING=/conf.json

check_conf(){
  if [ -n "$1" ] && [ -f "$1" ];then
    declare -g CONF_SETTING="$1"
  fi
}

# TODO 提示信息的函数要改一下
msg() {
	msg=$1
	echo "Info: ${msg}"
}

error() {
	error=$1
	echo "Error: ${error}"
}

warn() {
	warn=$1
	echo "Warn: ${warn}"
}

update_local() {
    local DI_LOCALE=$1
    DI_LOCALE=${DI_LOCALE:-en_US}

    export LANGUAGE=${DI_LOCALE}
    export LANG=${DI_LOCALE}.UTF-8
    export LC_ALL=
}

update_grub_local() {
    update_local $1
    [ -x /usr/sbin/update-grub ] && /usr/sbin/update-grub
}

setup_locale() {
  local DI_LOCALE LOCALE
  DI_LOCALE=$(jq -r ".language.locale" ${CONF_SETTING})
  #DI_LOCALE=$1

  DI_LOCALE=${DI_LOCALE:-en_US}
  LOCALE=${DI_LOCALE%.*}

  # Disable all locales first.
  sed -i 's/^\([^#].*\)$/# \1/g' /etc/locale.gen

  # Always generate en_US locale.
  msg "Generating locale: en_US ${LOCALE}"
  sed -i "s/# \(en_US\.UTF-8.*$\)/\1/g" /etc/locale.gen

  # generate user selected locale.
  sed -i "s/# \(${LOCALE}[\. ]UTF-8.*$\)/\1/g" /etc/locale.gen

  # TODO arch parse
  # For non-x86 platform, also enables non-UTF8 charset.
  #if ! is_x86 && test x${LOCALE} = xzh_CN; then
  #  sed -i "s/# \(${LOCALE}\.GBK.*$\)/\1/g" /etc/locale.gen
  #  sed -i "s/# \(${LOCALE}\.GB18030.*$\)/\1/g" /etc/locale.gen
  #  sed -i "s/# \(${LOCALE}\.GB2312.*$\)/\1/g" /etc/locale.gen
  #fi

  # 获取/etc/locale.gen locale值
  LANG=${LOCALE}.UTF-8
  if [ $(grep -c "${LOCALE}\.UTF-8" /etc/locale.gen) -eq 0 ]; then
    LANG=${LOCALE}
  fi

  cat > /etc/default/locale << EOF
LANG=${LANG}
LANGUAGE=${LOCALE}
EOF

  # Re-generate localisation files.
  /usr/sbin/locale-gen

  touch -c /usr/share/applications/*

  # Check locale
  if ls /usr/share/i18n/locales | grep -q "\<${LOCALE}\>"; then
    msg "${LOCALE} is available"
  else
    msg "${LOCALE} is not available, Fallback to en_US"
    unset LOCALE
  fi

  # Update grub based on current locale
  update_grub_local ${DI_LOCALE}
}

#LOCALE=$1
check_conf "$@"
setup_locale #$LOCALE

#! /bin/bash


# Set lightdm as default display manager.
setup_default_dm() {
  cat > /etc/X11/default-display-manager <<EOF
/usr/sbin/lightdm
EOF
}

enable_deepin_lightdm_greeter() {
  local CONF_FILE=/etc/lightdm/lightdm.conf
  if [ -f "${CONF_FILE}" ]; then
    sed -i -r \
      -e "s|^#.*greeter-session=.*\$|greeter-session=lightdm-deepin-greeter|" \
      -e "s|^#.*user-session=.*\$|user-session=deepin|" \
      "${CONF_FILE}"
  fi
}

main() {
  if [ -f /etc/lightdm/lightdm.conf ];then
    setup_default_dm
    if [ -f /usr/bin/lightdm-deepin-greeter ];then
      enable_deepin_lightdm_greeter
    fi
  fi
}

main


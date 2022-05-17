#!/bin/bash

CONF_SETTING=/conf.json

check_conf(){
  if [ -n "$1" ] && [ -f "$1" ];then
    declare -g CONF_SETTING="$1"
  fi
}

# Setup keyboard layout and model.
setup_keyboard() {
  local XKBLAYOUT XKBVARIANT XKBMODEL XKBOPTIONS

  XKBLAYOUT=$(jq -r ".keyboard.xkblayout" ${CONF_SETTING})
  XKBVARIANT=$(jq -r ".keyboard.xkbvariant" ${CONF_SETTING})
  XKBOPTIONS=$(jq -r ".keyboard.xkboptions" ${CONF_SETTING})
  XKBMODEL=$(jq -r ".keyboard.xkbmodel" ${CONF_SETTING})

  # XKBLAYOUT=$1
  # XKBVARIANT=$2
  # XKBMODEL=$3
  # XKBOPTIONS=$4

  XKBMODEL=${XKBMODEL:-pc105}
  XKBLAYOUT=${XKBLAYOUT:-us}

  cat > /etc/default/keyboard << EOF
# Check /usr/share/doc/keyboard-configuration/README.Debian for
# documentation on what to do after having modified this file.

# The following variables describe your keyboard and can have the same
# values as the XkbModel, XkbLayout, XkbVariant and XkbOptions options
# in /etc/X11/xorg.conf.

XKBMODEL="${XKBMODEL}"
XKBLAYOUT="${XKBLAYOUT}"
XKBVARIANT="${XKBVARIANT}"
XKBOPTIONS="${XKBOPTIONS}"

# If you don't want to use the XKB layout on the console, you can
# specify an alternative keymap.  Make sure it will be accessible
# before /usr is mounted.
# KMAP=/etc/console-setup/defkeymap.kmap.gz
EOF
}

# XKBLAYOUT=$1
# XKBVARIANT=$2
# XKBMODEL=$3
# XKBOPTIONS=$4
check_conf "$@"
setup_keyboard #$XKBLAYOUT $XKBVARIANT $XKBMODEL $XKBOPTIONS

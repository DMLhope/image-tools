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

add_user_to_existed_group() {
  local USER=$1
  local GROUP=$2
  if grep -q "^${GROUP}:" /etc/group 2>/dev/null; then
    gpasswd -a "${USER}" "${GROUP}"
  else
    warn "No group found ${GROUP}"
  fi
}

# Setup username, password and hostname.
setup_username_password_hostname() {
  local USERNAME HOSTNAME PASSWORD ROOTPASSWORD REAL_PASSWORD REAL_ROOTPASSWORD
  USERNAME=$(jq -r ".user.name" ${CONF_SETTING})
  PASSWORD=$(jq -r ".user.password" ${CONF_SETTING})
  HOSTNAME=$(jq -r ".user.hostname" ${CONF_SETTING})
  ROOTPASSWORD=$(jq -r ".user.rootpassword" ${CONF_SETTING})

  # USERNAME=$1
  # PASSWORD=$2
  # HOSTNAME=$3
  # ROOTPASSWORD=$4

  # TODO PASSWD CHECK
  # [ -z "${USERNAME}" ] && error "Variable USERNAME not set. Abort!"
  #  if [ x"${PASSWORD_MIN_LEN}" != x0 -a -z "${PASSWORD}" ]; then
  #   error "Variable PASSWORD not set. Abort!"
  # fi
  # HOSTNAME="${HOSTNAME:-deepin}"

  # TODO clear password after set
  # Reset password in settings file
  #installer_set "system_info_default_password" ""
  #installer_set "PASSWORD" ""
  #installer_set "system_info_default_root_password" ""
  #installer_set "ROOTPASSWORD" ""

  msg "create user: ${USERNAME}"
  if [[ -d /home/${USERNAME} ]]; then
      mv /home/${USERNAME} /home/${USERNAME}_recovery
      userdel ${USERNAME}
  fi
  groupdel ${USERNAME}
  groupdel ${USERNAME}

  useradd -U -m --skel /etc/skel --shell /bin/bash ${USERNAME}

  # Update password.
  if [ -z "${PASSWORD}" ]; then
      msg "set password to empty"
      passwd -d "${USERNAME}"
  else
    REAL_PASSWORD=$(echo "${PASSWORD}" | base64 -d)
    echo "${USERNAME}:${REAL_PASSWORD}" | chpasswd
  fi
  
  # Update root password. 
  if [ -n "${DI_ROOTPASSWORD}" ]; then
    REAL_ROOTPASSWORD=$(echo "${ROOTPASSWORD}" | base64 -d)
    msg "--- ROOTPASSWORD = <${ROOTPASSWORD}>--- "
  fi

  if [ -n "${REAL_ROOTPASSWORD}" ]; then
    echo "root:${REAL_ROOTPASSWORD}" | chpasswd
  fi

  # Add user to groups.
  set +e
  add_user_to_existed_group "${USERNAME}" lp
  add_user_to_existed_group "${USERNAME}" lpadmin
  add_user_to_existed_group "${USERNAME}" netdev
  add_user_to_existed_group "${USERNAME}" network
  add_user_to_existed_group "${USERNAME}" sambashare
  add_user_to_existed_group "${USERNAME}" scanner
  add_user_to_existed_group "${USERNAME}" storage
  add_user_to_existed_group "${USERNAME}" sudo
  add_user_to_existed_group "${USERNAME}" users
  add_user_to_existed_group "${USERNAME}" wheel
  set -e

  # Chown owner and group to current user if uid mismatch.
  USER_HOME=/home/${USERNAME}
  if [[ -d "${USER_HOME}" ]]; then
    USER_ID=$(id -u "${USERNAME}")
    GROUP_ID=$(id -g "${USERNAME}")
    FOLDER_UID=$(stat -c "%u" "${USER_HOME}")
    FOLDER_GID=$(stat -c "%g" "${USER_HOME}")
    msg "${USER_HOME}: ${USER_ID}:${GROUP_ID}:${FOLDER_UID}:${FOLDER_GID}"

    if [ "${USER_ID}" -ne "${FOLDER_UID}" -o \
      "${GROUP_ID}" -ne "${FOLDER_GID}" ]; then
      msg "Fix HOME directory permission at ${USERNAME}."
      chown -hR "${USERNAME}:${USERNAME}" "${USER_HOME}"
    fi
  else
    warn "${USER_HOME} does not exist"
  fi

  # Setup hostname.
  msg "Set Hostname to ${HOSTNAME}"
  echo "${HOSTNAME}" | tee /etc/hostname

  cat > /etc/hosts << EOF
127.0.0.1	localhost
127.0.1.1	${HOSTNAME}

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

  # TODO System has not been booted with systemd as init system (PID 1). Can't operate.
  #hostnamectl set-hostname ${HOSTNAME}

if [[ -d /home/${USERNAME}_recovery ]]; then
   rm -rf /home/${USERNAME}
   mv /home/${USERNAME}_recovery /home/${USERNAME}
fi
}

# USERNAME=$1
# PASSWORD=$2
# HOSTNAME=$3
# ROOTPASSWORD=$4
check_conf "$@"
setup_username_password_hostname #$USERNAME $PASSWORD $HOSTNAME $ROOTPASSWORD

#!/usr/bin/env bash

# This is the name of the process we assume to be always present and to have been run for the current
# user. For a headless install, this might be different.
PERVASIVE_PROCESS="${NORDVPN_RECONNECTOR_PREVASIVE_PROCESS-Xorg}"

# This is where we will copy the executable script.
INSTALL_LOCATION="${NORDVPN_RECONNECTOR_INSTALL_LOCATION-/opt/nordvpn-reconnector}"

# This is the location of the symbolic link in PATH.
PATH_BINARY="${NORDVPN_RECONNECTOR_PATH_BINARY-/usr/bin/nordvpn-reconnector}"

app_check_root() {
  [[ "$(id -u)" != "0" ]] && echo "This script must be executed as privileged." && exit 1
}

app_check_install() {
  if [[ ! -f "${INSTALL_LOCATION}/nordvpn-reconnect.sh" ]];
  then
    echo "Service executable has not been installed. Please run $0 install first"
    exit 0
  fi
  if [[ ! -f "${PATH_BINARY}" ]];
  then
    echo "Service executable has not been installed. Please run $0 install first"
    exit 0
  fi
  if [[ ! -f /etc/systemd/user/nordvpn-reconnector.service ]];
  then
    echo "Service unit has not been installed. Please run $0 install first"
    exit 0
  fi
}

app_current_user() {
  # shellcheck disable=SC2009
  ps aux | grep -v grep | grep "${PERVASIVE_PROCESS}" | head -n 1 | cut -d' ' -f 1
}

app_systemctl_command() {
  local verbose="false"
  if [[ "$1" == "-v" ]];
  then
    verbose="true"
    shift
  fi
  local command="$1"
  command="systemctl ${command} --machine=$(app_current_user)@.host --user nordvpn-reconnector.service"
  if [[ "${verbose}" != "true" ]];
  then
    command="${command} > /dev/null"
  fi
  eval "${command} 2>&1"
}

app_systemctl_link() {
  app_systemctl_command -v "status" | grep -E "nordvpn-reconnector.service;\s*(enabled|disabled)" | sed -E "s/^.*nordvpn-reconnector.service;\s*(enabled|disabled).*$/\1/"
}

app_install() {
  app_check_root

  app_uninstall

  cd "$(dirname "${0}")" || exit 1
  echo " - Installing nordvpn-connector"
  echo "   - Copying the script to ${INSTALL_LOCATION}"
  mkdir -p "${INSTALL_LOCATION}"
  cp "$(pwd)/nordvpn-reconnect.sh" "${INSTALL_LOCATION}"
  cp "$(pwd)/icon.png" "${INSTALL_LOCATION}"
  chmod +x "${INSTALL_LOCATION}/nordvpn-reconnect.sh"
  echo "   - Adding symbolic link at ${PATH_BINARY}"
  ln -s "${INSTALL_LOCATION}/nordvpn-reconnect.sh" "${PATH_BINARY}"
  echo "   - Copying service unit definition for all users"
  cp "$(pwd)/nordvpn-reconnector.service" /etc/systemd/user/nordvpn-reconnector.service
}

app_uninstall() {
  app_check_root
  echo " - Uninstalling nordvpn-reconnector"
  if pgrep -f nordvpn-reconnector > /dev/null;
  then
    echo
    echo "Service nordvpn-reconnector is still running in the background. Please stop it first using:"
    echo "   $0 stop"
    exit 1
  fi
  if [[ "$(app_systemctl_link)" == "enabled" ]];
  then
    echo
    echo "Service nordvpn-reconnector is still enabled. Removing it may cause issues on next login."
    echo "Please disable it first by running:"
    echo "   $0 disable"
    exit 0
  fi
  echo "   - Removing the executable"
  rm -rf "${INSTALL_LOCATION}"
  echo "   - Removing the symbolic link"
  rm -rf "${PATH_BINARY}"
  echo "   - Removing the service unit definition"
  rm -rf /etc/systemd/user/nordvpn-reconnector.service
}

app_enable() {
  app_check_install
  echo " - Enabling service nordvpn-reconnector.service"
  app_systemctl_command enable
}

app_start() {
  app_check_install
  echo " - Starting service nordvpn-reconnector.service"
  app_systemctl_command start
}

app_disable() {
  echo " - Disabling service nordvpn-reconnector.service"
  app_systemctl_command disable
}

app_stop() {
  echo " - Stopping service nordvpn-reconnector.service"
  app_systemctl_command stop
}

app_run() {
  local command="$1"
  case "${command}" in
  install)
    app_install
    ;;
  uninstall)
    app_uninstall
    ;;
  enable)
    app_enable
    ;;
  disable)
    app_disable
    ;;
  start)
    app_start
    ;;
  stop)
    app_stop
    ;;
  *)
    echo "Unknown command ${command}"
    exit 1
  esac
}

app_main() {
  if [[ $# == 0 ]];
  then
    echo "Usage: $0 <command1> [<command2> <command3> ...]"
    echo
    echo "Available commands are:"
    echo " - install: installs this library into ${INSTALL_LOCATION}"
    echo " - uninstall: uninstalls the library"
    echo " - enable: enables the service for the current user"
    echo " - disable: disables the service for the current user"
    echo " - start: starts the service for the current user"
    echo " - stop: stops the service for the current user"
    echo
    echo "For example, to install, enable, and then start the service run:"
    echo "  $0 install enable start"
    echo
    echo "See README.md for more details."
    exit 0
  fi

  while [[ "$#" -gt 0 ]];
  do
    app_run "$1"
    shift
  done
}

app_main "${@}"
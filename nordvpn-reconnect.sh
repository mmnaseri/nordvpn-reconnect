#!/usr/bin/env bash

MAX_UPTIME=${NORDVPN_MAX_UPTIME-2 hours}
NOTIFY=${NORDVPN_RECONNECT_NOTIFY-false}
KILLER_REQUEST_FILE="${NORDVPN_KILLER_REQUEST_FILE-/tmp/nordvpnd-killer.ask}"

#### Time utilities.

time_get_component() {
  local component="$1"
  local summary="$2"
  if ! echo "${summary}" | grep -q -o -E "[[:digit:]]+ ${component}"; then
    echo 0
  else
    echo "${summary}" | sed -E "s/^.* ([[:digit:]]+) ${component}.*$/\1/"
  fi
}

time_to_sec() {
  local str=" $1"
  local seconds=0
  seconds=$((seconds + $(time_get_component "day" "${str}")))
  seconds=$((seconds * 24 + $(time_get_component "hour" "${str}")))
  seconds=$((seconds * 60 + $(time_get_component "min" "${str}")))
  seconds=$((seconds * 60 + $(time_get_component "sec" "${str}")))
  echo "${seconds}"
}

time_from_sec() {
  local value="$1"
  local str
  if [[ $((value % 60)) != 0 ]]; then
    str=" $((value % 60)) seconds"
    value=$((value - (value % 60)))
  fi
  value=$((value / 60))
  if [[ $((value % 60)) != 0 ]]; then
    str=" $((value % 60)) minutes${str}"
    value=$((value - (value % 60)))
  fi
  value=$((value / 60))
  if [[ $((value % 24)) != 0 ]]; then
    str=" $((value % 24)) hours${str}"
    value=$((value - (value % 24)))
  fi
  value=$((value / 24))
  if [[ ${value} -gt 0 ]]; then
    str="${value} days${str}"
  fi
  if [[ -z "${str}" ]]; then
    echo "0 seconds"
    return 0
  fi
  echo "${str}" | sed -E "s/^ +//"
}

## NordVPN interfacing.

## Checks whether or not NordVPN client is available as an executable in the path.
## Use the return code.
nordvpn_is_available() {
  which nordvpn >/dev/null 2>&1
}

## Checks for the uptime of the current connection. Returns the number of seconds the
## connection has been active for.
## If not currently connected, returns zero.
nordvpn_check_uptime() {
  local status
  status="$(nordvpn status | grep Uptime 2>&1)"
  if [[ -z "${status}" ]]; then
    echo 0
  else
    time_to_sec "${status}"
  fi
}

## Returns the current server NordVPN is connected to.
nordvpn_server() {
  nordvpn status | grep server | sed -E "s/^.*server: ([^.]+)\..*$/\1/"
}

## Application methods.

## Changes into the directory the application main script is located at. We
## do this so that we can create a path to the icon file.
app_change_directory() {
  local path
  if [[ -z "$(readlink -f "${0}")" ]]; then
    path="${0}"
  else
    path="$(readlink -f "${0}")"
  fi
  cd "$(dirname "${path}")" || exit 1
}

## If NOTIFY is set to <true>, it will send a notification via Gnome's notify-send.
app_notify() {
  if [[ "${NOTIFY}" != "true" ]]; then
    return 0
  fi
  notify-send -a "NordVPN Reconnector" -i "file://$(pwd)/icon.png" -c "network.connected" 'NordVPN Reconnector' "VPN connection re-established"
}

## Attempts to reconnect to the same server we are currently connected to and sends a notification
## of the fact if needed.
app_reconnect() {
  echo "Attempting to reconnect."
  local server
  server="$(nordvpn_server)"
  ## Try to reconnect the normal way.
  if ! timeout 1s nordvpn connect "${server}"; then
    ## If after 15 seconds we couldn't reconnect, kill the service forcibly.
    local pid
    pid="$(pgrep -x nordvpnd)"
    echo "Attempting to kill process ${pid} for service nordvpnd"
    ## Kill the service and try again.
    if ! kill -9 "${pid}" >/dev/null >&1; then
      ## If we couldn't kill the service, let the user know, and attempt to ask the sister service to do the dirty work.
      echo "Failed to kill service; it may be that the service is running at a higher privilege than this script"
      echo "Asking nordvpnd-killer.service to take care of this for us."
      touch "${NORDVPN_KILLER_REQUEST_FILE}"
      sleep 15s
      if [[ -f "${NORDVPN_KILLER_REQUEST_FILE}" ]]; then
        echo "Seems like we failed to do this by asking nordvpnd-killer.service; please make sure that the service is running."
      fi
    fi
    ## Attempt to reconnect to the same server as before, if not possible, connect to an automatically picked server.
    nordvpn connect "${server}" || nordvpn connect
  fi
  app_notify
}

## Checks to see if the reconnector has been locked. A lock can be placed by simply
## creating a file at /tmp/nordvpn-reconnect.lock
app_is_locked() {
  test -f /tmp/nordvpn-reconnect.lock
}

## The main method. The first parameter is an optional value of how long we should wait before reconnecting
## to VPN.
## Parameter 1: maximum uptime. This can be either the number of seconds or a string supported by time_to_sec.
app_main() {
  if ! nordvpn_is_available; then
    echo "NordVPN client is not available"
    exit 1
  fi

  local max_uptime="${1-${MAX_UPTIME}}"

  if [[ -z "${max_uptime}" ]]; then
    echo "No maximum runtime specified. Either set NORDVPN_MAX_UPTIME or pass in the first parameter."
    exit 1
  fi

  if [[ -z "$(echo "${max_uptime}" | sed -E 's/^[[digit]]+$//')" ]]; then
    max_uptime="$(time_from_sec "${max_uptime}")"
  fi

  max_uptime="$(time_to_sec "${max_uptime}")"

  local check_interval=$((max_uptime / 10))

  # Change to the current directory.
  app_change_directory

  echo "Initializing NordVPN reconnector with a maximum uptime of $(time_from_sec "${max_uptime}")"
  [[ "${NOTIFY}" != "true" ]] && echo "Desktop notifications are disabled."

  while true; do
    if app_is_locked; then
      echo "Lock in place. Not going to check for reconnection."
    else
      local current_uptime
      current_uptime=$(nordvpn_check_uptime)
      if [[ ${current_uptime} -gt ${max_uptime} ]]; then
        echo "Current uptime is $(time_from_sec "${current_uptime}"), which is greater than $(time_from_sec "${max_uptime}")"
        app_reconnect
      fi
    fi
    echo "Checking again in $(time_from_sec "${check_interval}")"
    sleep "${check_interval}s"
  done
}

app_main "${@}"

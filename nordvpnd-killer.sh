#!/usr/bin/env bash

REQUEST_FILE="${NORDVPN_KILLER_REQUEST_FILE-/tmp/nordvpnd-killer.ask}"

[[ "$(id -u)" != "0" ]] && echo "This script must be executed as root." && exit 1

echo "Starting NordVPNd Killer."
echo "Drop a file at ${REQUEST_FILE} to ask for a kill."

while true;
do
  if [[ ! -f "${REQUEST_FILE}" ]];
  then
    sleep 10s
    continue
  fi
  echo "Received request to forcibly kill nordvpnd"
  pid="$(pgrep -x nordvpnd)"
  echo "Attempting to kill nordvpn at PID ${pid}"
  kill -9 "${pid}"
  rm -rf "${REQUEST_FILE}"
  echo "Waiting to see if the service comes up on its own in 2 seconds ..."
  sleep 2s
  if [[ -z "$(pgrep -x nordvpnd)" ]];
  then
    echo "NordVPN daemon needs some help recovering. Using systemctl"
    systemctl start nordvpnd
    echo "Waiting to see if NordVPN daemon recovered after our nudge."
    sleep 2s
    if [[ -z "$(pgrep -x nordvpnd)" ]];
    then
      echo "It seems like systemctl wasn't able to start nordvpnd. See <journalctl -u nordvpnd> or <systemctl status nordvpnd> for more information."
    fi
  fi
  echo "My job is done. Going back to sleep ..."
done
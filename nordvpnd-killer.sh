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
  echo "My job is done. Going back to sleep ..."
done
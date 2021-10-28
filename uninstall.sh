#!/usr/bin/env bash

[[ "$(id -u)" != "0" ]] && echo "This script must be executed as privileged." && exit 1

echo "- Removing existing service definition if any."
systemctl stop nordvpn-reconnector.service > /dev/null 2>&1
systemctl disable nordvpn-reconnector.service > /dev/null 2>&1
rm -rf /usr/bin/nordvpn-reconnector
rm -rf /etc/systemd/system/nordvpn-reconnector.service

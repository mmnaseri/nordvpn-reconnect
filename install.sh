#!/usr/bin/env bash

[[ "$(id -u)" != "0" ]] && echo "This script must be executed as privileged." && exit 1

cd "$(dirname "${0}")" || exit 1

./uninstall.sh

echo "- Creating service definition and binary"
ln -s "$(pwd)/nordvpn-reconnect.sh" "/usr/bin/nordvpn-reconnector"
cp "$(pwd)/nordvpn-reconnector.service" "/etc/systemd/system/nordvpn-reconnector.service"

echo
echo "Do not forget to enable and run this service:"
echo "systemctl enable nordvpn-reconnector.service"
echo "systemctl start nordvpn-reconnector.service"
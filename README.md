# NordVPN Reconnector

This is a simple script that is able to instruct the NordVPN client to reconnect
to the server it is currently connected to after a certain amount of time has
passed on a recurring basis.

The problem this script is trying to solve is the unreliability of the NordVPN
Linux client wherein it will frequently hang after it has been connected without
interruptions for long periods of time. When the client enters this state, any
action fails, including attempting to disconnect or restart the `nordvpn(d).service`.

In such a state, the only recourse is to reboot the machine. Which is less than ideal.

## Usage

You can either run the main `nordvpn-reconnect.sh` script individually, or run it as
a daemon. A convenience script has been provided which installs the script as a symbolic
link under `/usr/bin` and also adds a daemon unit to `systemctl`, which you can then
enable and run.

### How it works

The script consults the `nordvpn` client for uptime, and if it has been more than a
preconfigured amount of time since it was connected to the current server (defaults
to 4 hours), it will reconnect to the same server, thus making sure that the connection
never stays open for more than that. The checking is done at intervals of one tenth of
the indicated maximum uptime, so, for four hours, that would be every 24 minutes.

### Running the script

The script takes a single, optional command line argument which is the maximum
runtime it should check for. This can be either a number given in seconds, or a
string with the format `X days Y hours Z minutes T seconds`, such as `4 hours 10 minutes`.

There are two environment variables which the script will consult:

- `NORDVPN_MAX_UPTIME`; indicates the default max uptime if the CLI parameter is not specified; defaults to `4 hours`.
- `NORDVPN_RECONNECT_NOTIFY`; decides if the script should send a notification via `notify-send`
 every time it reconnects; defaults to `false`.

A sample run with notifications (works on Gnome) and 1 hour uptime is:

```shell
NORDVPN_RECONNECT_NOTIFY=true ./nordvpn-reconnect.sh "1 hour"
```

### Using as a daemon

To use as a daemon, you just need to create a unit (see the provided example `.service` file)
and place it within reach of `systemctl`. The convenience install and uninstall scripts
are tested to work no Arch Linux, but should work on other distros as well. 

To use this as a daemon via the provided scripts, run:

```shell
sudo ./install.sh
sudo systemctl enable nordvpn-reconnector.service
sudo systemctl start nordvpn-reconnector.service
```

## Contribution

Feel free to open pull requests. I'm open to widening support if there is enthusiasm.

## Disclaimer

I am using this on my personal machine. Use at your own risk.
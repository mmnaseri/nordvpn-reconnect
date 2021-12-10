# NordVPN Reconnector

This is a simple script that is able to instruct the NordVPN client to reconnect
to the server it is currently connected to after a certain amount of time has
passed on a recurring basis.

The problem this script is trying to solve is the unreliability of the NordVPN
Linux client wherein it will frequently hang after it has been connected without
interruptions for long periods of time. When the client enters this state, any
action fails, including attempting to disconnect or restart the `nordvpn(d).service`.

In such a state, the only recourse is to reboot the machine. Which is less than ideal.

## Installation
To install nordvpn-reconnect I suggest closing the repository.

Follow these steps.

1. Open a terminal with 

    ctrl + t

2. If you do not have git installed, install it. Type `sudo apt install git`
3. type `sudo git clone https://github.com/mmnaseri/nordvpn-reconnect`. This will create a folder called "nordvpn-reconnect" in the current location.

4. type `cd nordvpn-reconnect` inside the terminal to enter the folder

5. For a simple installation type `sudo ./install.sh install`

6. If you want to install the code, start it and enable a service that automatically starts type instead `sudo ./install.sh install`

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

If reconnection requests fail, the script will attempt to kill NordVPNd. If that fails, it will need to
either be executed as root, or ask someone else who is to do the dirty work. That's why this script
comes with a sister: `nordvpnd-killer.sh`.

If you drop a file at `/tmp/nordvpnd-killer.ask` it will try to kill the service for you. The idea is that
you run the original script as your own user, and the other script as root, to have the least amount of
privilege handed to this script.

### Using as a daemon

To use as a daemon, you just need to create a unit (see the provided example `.service` file)
and place it within reach of `systemctl`. The convenience install script
is tested to work on Arch Linux and on Ubuntu 20.04, but should work on other distros as well. 

To use this as a daemon via the provided scripts, run:

```shell
sudo ./install.sh install
sudo ./install.sh enable
sudo ./install.sh start
```

Or more succinctly:

```shell
sudo ./install.sh install enable start
```

In the same vein, to remove the script and all its traces:

```shell
sudo ./install.sh stop disable uninstall
```

### Pausing the Service

If you drop a file at `/tmp/nordvpn-reconnect.lock`, the service will skip the current iteration.
If you keep that file in place, it is going to be the same as never executing this service at all.

## Contribution

Feel free to open pull requests. I'm open to widening support if there is enthusiasm.

## Disclaimer

I am using this on my personal machine. Use at your own risk.

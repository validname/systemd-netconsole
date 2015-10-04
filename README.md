# systemd-netconsole
Loads netconsole kernel module with support of all already initialized interfaces.

Use this systemd unit when your network card very slow initilizes and standard
methods to load console doesn't work (such as module options via configuration
of kernel parameters). Or if you have a network bridge on your interfaces.

Example:
```
# dmesg | less
...
[   10.061802] netpoll: netconsole: br0 doesn't exist, aborting
[   10.061803] netconsole: cleaning up
...
[   18.628427] br0: port 1(eno1) entered forwarding state
[   18.628664] IPv6: ADDRCONF(NETDEV_CHANGE): br0: link becomes ready
...
```

# Configuration
All configuration parameters and their descriptions are stored in the
/etc/default/netconsole file.

# Simple use

If you already have confuguration file in the /etc/modprobe.d with netconsole
options, then just copy them to /etc/default/netconsole.
```bash
# cat /etc/modprobe.d/netconsole.conf
options netconsole netconsole=6655@192.168.0.100/eno1,6666@192.168.0.1/00:01:21:d9:10:2c

# cat /etc/default/netconsole
NETCONSOLE_IF="eno1"
NETCONSOLE_SRC_IP="192.168.0.100"
NETCONSOLE_SRC_PORT=6665
NETCONSOLE_DST_IP="192.168.0.1"
NETCONSOLE_DST_PORT=6666
NETCONSOLE_DST_MAC="00:01:21:d9:10:2c"
```

# Advanced use

Automate previous example as much as possible.
```bash
# cat /etc/default/netconsole
NETCONSOLE_IF="eno1"
NETCONSOLE_SRC_IP="no"
NETCONSOLE_SRC_PORT=
NETCONSOLE_DST_IP="192.168.0.1"
NETCONSOLE_DST_PORT=6666
NETCONSOLE_DST_MAC="auto"
```

Broadcast kernel messages to local network.
```bash
# cat /etc/default/netconsole
NETCONSOLE_IF="eno1"
NETCONSOLE_SRC_IP="no"
NETCONSOLE_SRC_PORT=
NETCONSOLE_DST_IP="broadcast"
NETCONSOLE_DST_PORT=6666
NETCONSOLE_DST_MAC=""
```

# Expirienced use

Broadcast kernel messages to local networks from all interfaces
which has configured IPv4 address.
```bash
# cat /etc/default/netconsole
NETCONSOLE_IF="auto"
NETCONSOLE_SRC_IP="no"
NETCONSOLE_SRC_PORT=
NETCONSOLE_DST_IP="broadcast"
NETCONSOLE_DST_PORT=6666
NETCONSOLE_DST_MAC=""
```

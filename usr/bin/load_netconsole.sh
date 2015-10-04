#!/bin/bash

if [ -f /etc/default/netconsole ]; then
	. /etc/default/netconsole
else
	# hardcoded defaults
	NETCONSOLE_IF="auto"
	NETCONSOLE_SRC_IP="no"
	NETCONSOLE_SRC_PORT=
	NETCONSOLE_DST_IP="broadcast"
	NETCONSOLE_DST_PORT=6666
	NETCONSOLE_DST_MAC=""
fi

# converts IPv4 address to integer
function ipv4_to_i() {
	echo $1| awk -F '.' '{print $1*256*256*256+$2*256*256+$3*256+$4}'
}

# converts integer to IPv4 address
function i_to_ipv4() {
	local a1=$(($1/256/256/256))
	local temp=$(($1-$a1*256*256*256))
	local a2=$(($temp/256/256))
	local temp=$(($temp-$a2*256*256))
	local a3=$(($temp/256))
	local a4=$(($temp-$a3*256))
	echo "$a1.$a2.$a3.$a4"
}

# creates bit mask by length
function get_bit_mask() {
	l=$((32-$1))
	mask=0
	while [ $l -gt 0 ]; do
		mask=$((($mask<<1)+1))
		l=$(($l-1))
	done
	echo $mask
}

# clear all dynamic configuration if exists
find /sys/kernel/config/netconsole -maxdepth 1 -type d -delete 2>/dev/null
# unload module if it was already loaded
rmmod netconsole
# load configfs and netconsole module
modprobe configfs
modprobe netconsole

# check whether configfs was already mounted
cat /proc/mounts| egrep -q '^configfs /sys/kernel/config configfs'
if [ $? -gt 0 ]; then
	mount none -t configfs /sys/kernel/config
fi

# search IPv4 addresses on network interfaces
addresses_string=`ip address show| egrep '^[[:blank:]]+inet[[:blank:]]+'| awk '$NF!="lo" {print $0}'`
addresses=`echo "$addresses_string"| awk '{print $2}'`

for address in $addresses; do
	interface=`echo $addresses_string| awk -v a="$address" '$2=a {print $NF}'`
	ip_addr=`echo $address| cut -d '/' -f1`
	netmask=`echo $address| cut -d '/' -f2`

	if [ "$netmask" == "32" ]; then
		# skip /32 addresses
		continue;
	fi

	if [ "$NETCONSOLE_IF" != "auto" ] && [ "$NETCONSOLE_IF" != "AUTO" ] && [ "$interface" != "$NETCONSOLE_IF" ]; then
		# skip this address/interface
		continue;
	fi

	# send source
	if [ "$NETCONSOLE_SRC_IP" == "no" ] || [ "$NETCONSOLE_SRC_IP" == "NO" ]; then
		src_ip=""
		src_port=""
	elif [ "$NETCONSOLE_SRC_IP" == "auto" ] || [ "$NETCONSOLE_SRC_IP" == "AUTO" ]; then
                src_ip="$ip_addr"
                src_port="$NETCONSOLE_SRC_PORT"
	else
                src_ip="$NETCONSOLE_SRC_IP"
                src_port="$NETCONSOLE_SRC_PORT"
	fi

	# destination to send
	dst_port=$NETCONSOLE_DST_PORT
	if [ "$NETCONSOLE_DST_IP" == "broadcast" ] || [ "$NETCONSOLE_DST_IP" == "BROADCAST" ]; then
	        address_int=`ipv4_to_i $ip_addr`
		netmask_int=`get_bit_mask $netmask`
		dst_ip=`i_to_ipv4 $(($address_int|$netmask_int))`
		dst_mac="ff:ff:ff:ff:ff:ff"
	else
                dst_ip="$NETCONSOLE_DST_IP"
		if [ "$NETCONSOLE_DST_MAC" == "auto" ] || [ "$NETCONSOLE_DST_MAC" == "AUTO" ]; then
			# determine MAC address of destination
			dst_mac=`arping -w 3 -c 1 -I $interface $dst_ip 2>/dev/null| egrep "^Unicast reply from $dst_ip"| awk '{print $5}' 2>/dev/null| tr -d '[]'`
		else
			dst_mac="$NETCONSOLE_DST_MAC"
		fi
	fi

	# apply
	target="$interface-$ip_addr"
	mkdir /sys/kernel/config/netconsole/$target
	echo "$interface" > /sys/kernel/config/netconsole/$target/dev_name
	if [ "$src_ip" ]; then
		echo "$src_ip" > /sys/kernel/config/netconsole/$target/local_ip
	fi
	if [ "$src_port" ]; then
	        echo "$src_port" > /sys/kernel/config/netconsole/$target/local_port
	fi
        echo "$dst_ip" > /sys/kernel/config/netconsole/$target/remote_ip
        echo "$dst_port" > /sys/kernel/config/netconsole/$target/remote_port
	if [ "$dst_mac" ]; then
	        echo "$dst_mac" > /sys/kernel/config/netconsole/$target/remote_mac
	fi
        echo "1" > /sys/kernel/config/netconsole/$target/enabled
done

#!/bin/sh

# WifiSwitch -- Simple Multiple Wifi Connector for OpenWrt

# Based on YAWAC Yet Another Wifi Auto Connect (YAWAC) https://github.com/mehdichaouch/YAWAC
#	is a shell script to connect to a dataset of wireless connection and free hotspot like FreeWifi. 
# It's works on OpenWrt.

# This script is based on my use scenario and it works! Hope you find it useful too..
# Simple scenario using this script : Having 2nd Wireless USB (radio1) and wanna connect seamlessly
# within different SSID, whether defined Access Point SSID is discovered.
# Then, run this script using Cron every minute. * * * * *

. /etc/config/wifiswitch

connect(){
	uci set wireless.@wifi-iface[1]="wifi-iface"
	uci set wireless.@wifi-iface[1].ssid="$ssid"
	uci set wireless.@wifi-iface[1].encryption="$encryption"
	uci set wireless.@wifi-iface[1].device="radio1"
	uci set wireless.@wifi-iface[1].mode="sta"
	uci set wireless.@wifi-iface[1].network="wwan"
	uci set wireless.@wifi-iface[1].key="$key"
	uci set wireless.@wifi-iface[1].macaddr="$macaddr"
	uci set wireless.@wifi-iface[1].disabled=1
	uci commit wireless
	wifi down radio1

	sleep 5
	uci set wireless.@wifi-iface[1].disabled=0
	uci commit wireless
	sleep 5
	wifi up radio1
}

# reset disappearing interface, can happen when me disabled wifi via luci
testInterface=$(ifconfig|grep wlan0)
if [ ! "$testInterface" ]; then
	ssid="dummy"
	key="d"
	connect
	sleep 5
fi


#check wifi if still assoc-ed
status=$(iw dev wlan0 station dump)
if [ "$status" ]; then
	exit 0
fi

#scan ssid
scanres=
while [ "$scanres" = "" ]; do
	#sometimes it shows nothing, so better to ensure we did a correct scan
	scanres=$(iw wlan0 scan | grep SSID)
	sleep 5
done

n=0
#Match our ssid list to discovered ssid before
while [ "1" ]; do
	n=$(expr "$n" + "1")

	ssid=net"$n"_ssid
	eval ssid=\$$ssid

	active=$(echo $scanres | grep "$ssid">&1 )
	if [ "$active" ]; then
		break
	fi

	if [ "$ssid" = "" ]; then
		#ssid not existing or empty. Assume it's the end of the wlist file
		exit 0
	fi
done

#assign available ssid var
ssid=net"$n"_ssid
eval ssid=\$$ssid

ssid=net"$n"_ssid
encryption=net"$n"_encryption
key=net"$n"_key
macaddr=net"$n"_macaddr

eval ssid=\$$ssid
eval encryption=\$$encryption
eval key=\$$key
eval macaddr=\$$macaddr

connect

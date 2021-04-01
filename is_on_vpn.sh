#!/bin/sh

vpn=$(ip link show | grep tun0)
if [ "tun0" = "$vpn" ];
then
	echo 'true'
else
	echo 'false'
fi

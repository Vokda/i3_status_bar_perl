#!/bin/sh

vpn=$(ip link show | grep tun0)
if [ -n "$vpn" ];
then
	echo 'true'
else
	echo 'false'
fi

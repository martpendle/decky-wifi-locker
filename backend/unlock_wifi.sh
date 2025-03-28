#!/bin/bash

# Get the connected wifi Card Details and connected SSID
WIFI_CARD=$(nmcli dev status | grep wifi | grep -v disconnected | head -n1 | cut -d " " -f1)
LINK_INFO=$(iw dev $WIFI_CARD link)
SSID=$(echo $LINK_INFO | grep -o -P '(?<=SSID: ).*(?= freq)')

# Unlock Wifi by removing the BSSID lock
nmcli con mod "$SSID" 802-11-wireless.bssid ''
nmcli dev dis "$WIFI_CARD"
nmcli dev con "$WIFI_CARD"

# Output the SSID for feedback
echo "{\"ssid\":\"$SSID\"}"

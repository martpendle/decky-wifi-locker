#!/bin/bash

# Capture all output to variables
exec 2> >(tee /tmp/wifi_lock_error.log)

# Get the connected wifi Card Details and connected SSID/ BSSID
echo "Getting WiFi card details..." > /tmp/wifi_lock_debug.log
WIFI_CARD=$(nmcli dev status | grep wifi | grep -v disconnected | head -n1 | cut -d " " -f1)
echo "WiFi card: $WIFI_CARD" >> /tmp/wifi_lock_debug.log

LINK_INFO=$(iw dev $WIFI_CARD link)
echo "Link info: $LINK_INFO" >> /tmp/wifi_lock_debug.log

BSSID=$(echo "$LINK_INFO" | grep -o -P '(?<=Connected to ).*(?= \(on)' | tr '[:lower:]' '[:upper:]')
echo "BSSID: $BSSID" >> /tmp/wifi_lock_debug.log

# Extract SSID more reliably
SSID=$(echo "$LINK_INFO" | grep -o -P '(?<=SSID: ).*' | head -n1 | sed 's/freq.*$//')
# Remove trailing whitespace
SSID=$(echo "$SSID" | sed 's/[[:space:]]*$//')

# If SSID extraction failed, try to get it from NetworkManager
if [ -z "$SSID" ]; then
    echo "SSID extraction from iw failed, trying nmcli..." >> /tmp/wifi_lock_debug.log
    SSID=$(nmcli -t -f NAME connection show --active | head -n1)
    echo "SSID from nmcli: $SSID" >> /tmp/wifi_lock_debug.log
fi
echo "SSID: $SSID" >> /tmp/wifi_lock_debug.log

# Lock Wifi to the BSSID to stop background scanning.
echo "Locking WiFi to BSSID $BSSID..." >> /tmp/wifi_lock_debug.log

# Execute the commands directly - Decky should handle permissions with the _root flag
echo "Running NetworkManager commands..." >> /tmp/wifi_lock_debug.log

# Lock to BSSID
echo "Setting BSSID for $SSID to $BSSID..." >> /tmp/wifi_lock_debug.log
LOCK_RESULT=$(nmcli con mod "$SSID" 802-11-wireless.bssid "$BSSID" 2>&1)
LOCK_STATUS=$?
echo "Lock result (status $LOCK_STATUS): $LOCK_RESULT" >> /tmp/wifi_lock_debug.log

# Disconnect
echo "Disconnecting WiFi card..." >> /tmp/wifi_lock_debug.log
DISCONNECT_RESULT=$(nmcli dev dis "$WIFI_CARD" 2>&1)
DISCONNECT_STATUS=$?
echo "Disconnect result (status $DISCONNECT_STATUS): $DISCONNECT_RESULT" >> /tmp/wifi_lock_debug.log

# Reconnect
echo "Reconnecting WiFi card..." >> /tmp/wifi_lock_debug.log
CONNECT_RESULT=$(nmcli dev con "$WIFI_CARD" 2>&1)
CONNECT_STATUS=$?
echo "Connect result (status $CONNECT_STATUS): $CONNECT_RESULT" >> /tmp/wifi_lock_debug.log

# Check if BSSID is actually set
VERIFY_RESULT=$(nmcli connection show "$SSID" | grep bssid 2>&1)
echo "Verification: $VERIFY_RESULT" >> /tmp/wifi_lock_debug.log

# Determine success status
SUCCESS_STATUS=$([[ $LOCK_STATUS -eq 0 && $CONNECT_STATUS -eq 0 ]] && echo true || echo false)

# Output the SSID, BSSID and success status only, without debug logs
echo "{\"ssid\":\"$SSID\",\"bssid\":\"$BSSID\",\"success\":$SUCCESS_STATUS}"

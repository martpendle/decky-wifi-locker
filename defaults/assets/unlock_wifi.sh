#!/bin/bash

# Capture all output to variables
exec 2> >(tee /tmp/wifi_unlock_error.log)

# Get the connected wifi Card Details and connected SSID
echo "Getting WiFi card details..." > /tmp/wifi_unlock_debug.log
WIFI_CARD=$(nmcli dev status | grep wifi | grep -v disconnected | head -n1 | cut -d " " -f1)
echo "WiFi card: $WIFI_CARD" >> /tmp/wifi_unlock_debug.log

LINK_INFO=$(iw dev $WIFI_CARD link)
echo "Link info: $LINK_INFO" >> /tmp/wifi_unlock_debug.log

# Extract SSID more reliably
SSID=$(echo "$LINK_INFO" | grep -o -P '(?<=SSID: ).*' | head -n1 | sed 's/freq.*$//')
# Remove trailing whitespace
SSID=$(echo "$SSID" | sed 's/[[:space:]]*$//')

# If SSID extraction failed, try to get it from NetworkManager
if [ -z "$SSID" ]; then
    echo "SSID extraction from iw failed, trying nmcli..." >> /tmp/wifi_unlock_debug.log
    SSID=$(nmcli -t -f NAME connection show --active | head -n1)
    echo "SSID from nmcli: $SSID" >> /tmp/wifi_unlock_debug.log
fi
echo "SSID: $SSID" >> /tmp/wifi_unlock_debug.log

# Check current BSSID setting before unlocking
PREVIOUS_BSSID=$(nmcli connection show "$SSID" | grep bssid 2>&1)
echo "Previous BSSID setting: $PREVIOUS_BSSID" >> /tmp/wifi_unlock_debug.log

# Unlock Wifi by removing the BSSID lock
echo "Unlocking WiFi by removing BSSID lock..." >> /tmp/wifi_unlock_debug.log

# Execute the commands directly - Decky should handle permissions with the _root flag
echo "Running NetworkManager commands..." >> /tmp/wifi_unlock_debug.log

# Remove BSSID lock
echo "Removing BSSID for $SSID..." >> /tmp/wifi_unlock_debug.log
UNLOCK_RESULT=$(nmcli con mod "$SSID" 802-11-wireless.bssid '' 2>&1)
UNLOCK_STATUS=$?
echo "Unlock result (status $UNLOCK_STATUS): $UNLOCK_RESULT" >> /tmp/wifi_unlock_debug.log

# Disconnect
echo "Disconnecting WiFi card..." >> /tmp/wifi_unlock_debug.log
DISCONNECT_RESULT=$(nmcli dev dis "$WIFI_CARD" 2>&1)
DISCONNECT_STATUS=$?
echo "Disconnect result (status $DISCONNECT_STATUS): $DISCONNECT_RESULT" >> /tmp/wifi_unlock_debug.log

# Reconnect
echo "Reconnecting WiFi card..." >> /tmp/wifi_unlock_debug.log
CONNECT_RESULT=$(nmcli dev con "$WIFI_CARD" 2>&1)
CONNECT_STATUS=$?
echo "Connect result (status $CONNECT_STATUS): $CONNECT_RESULT" >> /tmp/wifi_unlock_debug.log

# Verify BSSID is removed
VERIFY_RESULT=$(nmcli connection show "$SSID" | grep bssid 2>&1)
echo "Verification after unlock: $VERIFY_RESULT" >> /tmp/wifi_unlock_debug.log

# Determine success status
SUCCESS_STATUS=$([[ $UNLOCK_STATUS -eq 0 && $CONNECT_STATUS -eq 0 ]] && echo true || echo false)

# Output the SSID and success status only, without debug logs
echo "{\"ssid\":\"$SSID\",\"success\":$SUCCESS_STATUS}"

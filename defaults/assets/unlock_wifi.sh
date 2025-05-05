#!/usr/bin/env bash

# Capture all output to variables
exec 2> >(tee /tmp/wifi_unlock_error.log)

# Get SSID from the first argument
SSID="$1"

if [ -z "$SSID" ]; then
    echo "{\"success\":false, \"message\":\"Error: SSID argument not provided to unlock script.\"}"
    echo "Error: SSID argument not provided." > /tmp/wifi_unlock_error.log
    exit 1
fi

# Get the connected wifi Card Details (still needed for disconnect/connect)
echo "Getting WiFi card details..." > /tmp/wifi_unlock_debug.log
WIFI_CARD=$(nmcli dev status | grep wifi | head -n1 | cut -d " " -f1) # Allow disconnected cards
echo "WiFi card: $WIFI_CARD" >> /tmp/wifi_unlock_debug.log

if [ -z "$WIFI_CARD" ]; then
    echo "{\"success\":false, \"message\":\"Error: Could not determine WiFi card.\"}"
    echo "Error: Could not determine WiFi card." >> /tmp/wifi_unlock_error.log
    exit 1
fi

echo "Attempting to unlock SSID: $SSID" >> /tmp/wifi_unlock_debug.log

# Check current BSSID setting before unlocking
PREVIOUS_BSSID=$(nmcli connection show "$SSID" | grep bssid 2>&1)
echo "Previous BSSID setting for $SSID: $PREVIOUS_BSSID" >> /tmp/wifi_unlock_debug.log

# Unlock Wifi by removing the BSSID lock
echo "Unlocking WiFi by removing BSSID lock for $SSID..." >> /tmp/wifi_unlock_debug.log

# Execute the commands directly
echo "Running NetworkManager commands..." >> /tmp/wifi_unlock_debug.log

# Remove BSSID lock
echo "Removing BSSID for $SSID..." >> /tmp/wifi_unlock_debug.log
UNLOCK_RESULT=$(nmcli con mod "$SSID" 802-11-wireless.bssid '' 2>&1)
UNLOCK_STATUS=$?
echo "Unlock result (status $UNLOCK_STATUS): $UNLOCK_RESULT" >> /tmp/wifi_unlock_debug.log

# Try to disconnect/reconnect if the card exists, but don't fail if it's already disconnected
DISCONNECT_STATUS=0
CONNECT_STATUS=0
if nmcli dev status | grep -q "^$WIFI_CARD.*connected"; then
    echo "Disconnecting WiFi card $WIFI_CARD..." >> /tmp/wifi_unlock_debug.log
    DISCONNECT_RESULT=$(nmcli dev dis "$WIFI_CARD" 2>&1)
    DISCONNECT_STATUS=$?
    echo "Disconnect result (status $DISCONNECT_STATUS): $DISCONNECT_RESULT" >> /tmp/wifi_unlock_debug.log

    echo "Reconnecting WiFi card $WIFI_CARD..." >> /tmp/wifi_unlock_debug.log
    CONNECT_RESULT=$(nmcli dev con "$WIFI_CARD" 2>&1)
    CONNECT_STATUS=$?
    echo "Connect result (status $CONNECT_STATUS): $CONNECT_RESULT" >> /tmp/wifi_unlock_debug.log
elif [ $UNLOCK_STATUS -eq 0 ]; then
    # If unlock command was successful but card wasn't connected, consider connect status as success
    # This allows unlocking even when out of range
    echo "WiFi card $WIFI_CARD not connected, skipping disconnect/reconnect." >> /tmp/wifi_unlock_debug.log
    CONNECT_STATUS=0
else
    # If unlock failed and card wasn't connected, connect status should reflect the unlock failure
    CONNECT_STATUS=$UNLOCK_STATUS
fi


# Verify BSSID is removed
VERIFY_RESULT=$(nmcli connection show "$SSID" | grep bssid 2>&1)
echo "Verification after unlock for $SSID: $VERIFY_RESULT" >> /tmp/wifi_unlock_debug.log

# Determine success status (Unlock must succeed, connect is optional if out of range)
SUCCESS_STATUS=$([[ $UNLOCK_STATUS -eq 0 ]] && echo true || echo false)

# Output the SSID and success status only, without debug logs
echo "{\"ssid\":\"$SSID\",\"success\":$SUCCESS_STATUS}"

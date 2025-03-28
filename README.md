# Decky WiFi Locker [![Chat](https://img.shields.io/badge/chat-on%20discord-7289da.svg)](https://deckbrew.xyz/discord)

## Overview

Decky WiFi Locker is a plugin for [decky-loader](https://github.com/SteamDeckHomebrew/decky-loader) that locks your Steam Deck's WiFi connection to a specific access point (BSSID) to prevent background scanning. This can help improve network stability and potentially reduce power consumption by preventing your device from constantly scanning for other networks.

## Features

- Lock WiFi to the current access point with a single button press
- Display the current SSID and BSSID when locked
- Easily unlock WiFi to resume normal operation
- Automatic unlocking when the plugin is unloaded
- Simple, user-friendly interface

## Why Use WiFi Locker?

By default, your Steam Deck (and most other devices) will periodically scan for WiFi networks in the background, even when connected to a network. This can cause brief interruptions in your connection, which might be noticeable during online gaming or streaming. By locking to a specific access point, you can:

- Reduce connection interruptions
- Potentially improve latency stability
- Slightly reduce power consumption
- Prevent unwanted network switching

## Installation

### From Plugin Store

1. Install [decky-loader](https://github.com/SteamDeckHomebrew/decky-loader) if you haven't already
2. Open the Quick Access menu (⋯ button)
3. Select the Decky icon (the plug)
4. Go to the Store tab
5. Find "WiFi Locker" and click Install

### Manual Installation

1. Download the latest release ZIP file
2. Extract it to a temporary location
3. Copy the extracted folder to `/home/deck/homebrew/plugins/` on your Steam Deck
4. Restart your Steam Deck or reload Decky Loader

## Usage

1. Connect to your preferred WiFi network
2. Open the Quick Access menu (⋯ button)
3. Select the Decky icon (the plug)
4. Find and select "WiFi Locker"
5. Click "Lock WiFi to Current AP" to lock your connection
6. To unlock, open the plugin again and click "Unlock WiFi"

## How It Works

The plugin uses the following Linux commands to lock your WiFi connection:

```bash
# Get the connected WiFi Card Details and connected SSID/BSSID
WIFI_CARD=$(nmcli dev status | grep wifi | grep -v disconnected | head -n1 | cut -d " " -f1)
LINK_INFO=$(iw dev $WIFI_CARD link)
BSSID=$(echo $LINK_INFO | grep -o -P '(?<=Connected to ).*(?= \(on)' | tr '[:lower:]' '[:upper:]') 
SSID=$(echo $LINK_INFO | grep -o -P '(?<=SSID: ).*(?= freq)')

# Lock WiFi to the BSSID to stop background scanning
nmcli con mod $SSID 802-11-wireless.bssid $BSSID
nmcli dev dis $WIFI_CARD
nmcli dev con $WIFI_CARD
```

And to unlock:

```bash
nmcli con mod $SSID 802-11-wireless.bssid ''
nmcli dev dis $WIFI_CARD
nmcli dev con $WIFI_CARD
```

## Building From Source

1. Clone this repository
2. Install dependencies: `pnpm install`
3. Build the plugin: `pnpm build`
4. The built plugin will be in the `dist` directory

## License

This project is licensed under the [BSD 3-Clause License](LICENSE).

## Acknowledgments

- [SteamDeckHomebrew](https://github.com/SteamDeckHomebrew) for creating Decky Loader
- [decky-frontend-lib](https://github.com/SteamDeckHomebrew/decky-frontend-lib) for the UI components

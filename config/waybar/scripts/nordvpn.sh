#!/bin/bash

# Function to get VPN status
get_status() {
    if nordvpn status | grep -q "Status: Connected"; then
        echo "{\"text\": \"VPN: Connected \", \"tooltip\": \"You are connected to NordVPN.\", \"class\": \"connected\"}"
    else
        echo "{\"text\": \"VPN: Disconnected \", \"tooltip\": \"You are not connected to NordVPN.\", \"class\": \"disconnected\"}"
    fi
}

# Function to toggle VPN connection
toggle_vpn() {
    if nordvpn status | grep -q "Status: Connected"; then
        nordvpn disconnect
    else
        nordvpn connect
    fi
}

# Main logic
if [[ "$1" == "--toggle" ]]; then
    toggle_vpn
else
    get_status
fi

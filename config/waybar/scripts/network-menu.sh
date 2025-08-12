#!/bin/bash

# Pre-define Catppuccin Mocha colors
BACKGROUND='#1e1e2e'
FOREGROUND='#cdd6f4'
SELECTED_BG='#585b70'
SELECTED_FG='#cdd6f4'
BORDER='#b4befe'

# Get network status
WIFI_STATUS=$(nmcli radio wifi)
NET_STATUS=$(nmcli networking)

# Function to show the menu
show_menu() {
    # Get current connection and list of available Wi-Fi networks
    current_connection=$(nmcli -t -f NAME,TYPE connection show --active | grep 'wifi' | head -1 | cut -d: -f1)
    if [ -n "$current_connection" ]; then
        connected_entry="  Connected: $current_connection"
    else
        connected_entry="  Disconnected"
    fi

    wifi_list=$(nmcli -t -f SSID,SECURITY,BARS dev wifi list --rescan yes | sed 's/\\:/--/g' | grep -v '^--')

    # Build menu entries
    entries="$connected_entry\n"
    
    # Toggles first
    [ "$WIFI_STATUS" = "enabled" ] && entries+="󰖩  Disable Wi-Fi\n" || entries+="󰖪  Enable Wi-Fi\n"
    [ "$NET_STATUS" = "enabled" ] && entries+="󰱘  Disable Networking\n" || entries+="󰱗  Enable Networking\n"
    entries+="  Launch Connection Editor\n"
    entries+="<span size='2pt'>─</span>\n" # Separator
    
    # Add Wi-Fi networks to the list
    entries+=$(echo "$wifi_list" | sed "s/--/ /g" | awk -F' ' '{
        ssid=$1;
        sec=$2;
        bars=$3;
        if (sec != "") {
            icon=""; # Locked
        } else {
            icon=""; # Unlocked
        }
        print icon "  " ssid " (" bars ")"
    }')

    # Show wofi menu
    chosen=$(echo -e "$entries" | wofi --show dmenu -i \
        --style <(echo "
            * {
                font-family: \"Terminus (TTF)\", \"Font Awesome 6 Free\";
                font-size: 16px;
            }
            window {
                background-color: $BACKGROUND;
                border-radius: 12px;
                border: 2px solid $BORDER;
            }
            #input {
                background-color: $BACKGROUND;
                color: $FOREGROUND;
                border: none;
                padding: 5px;
            }
            #inner-box {
                margin: 5px;
            }
            #scroll {
                margin-top: 5px;
            }
            #entry {
                padding: 10px;
                color: $FOREGROUND;
                border-radius: 8px;
            }
            #entry:selected {
                background-color: $SELECTED_BG;
                color: $SELECTED_FG;
            }
        "))
    
    handle_choice "$chosen"
}

# Function to handle the user's choice
handle_choice() {
    choice="$1"
    
    case "$choice" in
        "󰖩  Disable Wi-Fi")
            nmcli radio wifi off
            ;;
        "󰖪  Enable Wi-Fi")
            nmcli radio wifi on
            ;;
        "󰱘  Disable Networking")
            nmcli networking off
            ;;
        "󰱗  Enable Networking")
            nmcli networking on
            ;;
        "  Launch Connection Editor")
            nm-connection-editor
            ;;
        ""*) # Ignore clicks on the "Connected" status line
            ;;
        *)
            # Connect to a new network
            ssid=$(echo "$choice" | awk '{$1=""; print $0}' | sed 's/ (.*//' | xargs)
            if [ -n "$ssid" ]; then
                # Check if it requires a password
                if nmcli -t -f SSID,SECURITY dev wifi list | grep -q "^$ssid:WPA"; then
                    password=$(wofi --show dmenu --prompt "Password for $ssid:")
                    nmcli dev wifi connect "$ssid" password "$password"
                else
                    nmcli dev wifi connect "$ssid"
                fi
            fi
            ;;
    esac
}

show_menu

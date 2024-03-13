#!/bin/bash

# Global constants
readonly DEFAULT_SYSTEM_VOLUME="Macintosh HD"
readonly DEFAULT_DATA_VOLUME="Macintosh HD - Data"

# Text formatting
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# Checks if a volume with the given name exists
checkVolumeExistence() {
    local volumeLabel="$*"
    diskutil info "$volumeLabel" >/dev/null 2>&1
}

# Returns the name of a volume with the given type
getVolumeName() {
    local volumeType="$1"
    # Getting the APFS Container Disk Identifier
    local apfsContainer=$(diskutil list internal physical | grep 'Container' | awk -F'Container ' '{print $2}' | awk '{print $1}')
    # Getting the Volume Information
    local volumeInfo=$(diskutil ap list "$apfsContainer" | grep -A 5 "($volumeType)")
    # Extracting the Volume Name from the Volume Information
    local volumeNameLine=$(echo "$volumeInfo" | grep 'Name:')
    # Removing unnecessary characters to get the clean Volume Name
    local volumeName=$(echo "$volumeNameLine" | cut -d':' -f2 | cut -d'(' -f1 | xargs)
    echo "$volumeName"
}

# Defines the path to a volume with the given default name and volume type
defineVolumePath() {
    local defaultVolume=$1
    local volumeType=$2

    if checkVolumeExistence "$defaultVolume"; then
        echo "/Volumes/$defaultVolume"
    else
        local volumeName
        volumeName="$(getVolumeName "$volumeType")"
        echo "/Volumes/$volumeName"
    fi
}

# Mounts a volume at the given path
mountVolume() {
    local volumePath=$1

    if [ ! -d "$volumePath" ]; then
        diskutil mount "$volumePath"
    fi
}

echo -e "${CYAN}*-------------------*---------------------*${NC}"
echo -e "${YELLOW}* Check MDM - Skip MDM Auto for MacOS by  *${NC}"
echo -e "${RED}*             SKIPMDM.COM                 *${NC}"
echo -e "${RED}*            Phoenix Team                  *${NC}"
echo -e "${CYAN}*-------------------*---------------------*${NC}"
echo ""

PS3='Please enter your choice: '
options=("Block MDM hosts" "Check MDM Enrollment" "Reboot" "Exit")

select opt in "${options[@]}"; do
    case $opt in
    "Block MDM hosts")
        echo -e "\n\t${GREEN}Blocking MDM hosts...${NC}\n"

        # Mount Volumes
        echo -e "${BLUE}Mounting volumes...${NC}"
        # Mount System Volume
        local systemVolumePath=$(defineVolumePath "$DEFAULT_SYSTEM_VOLUME" "System")
        mountVolume "$systemVolumePath"

        # Mount Data Volume
        local dataVolumePath=$(defineVolumePath "$DEFAULT_DATA_VOLUME" "Data")
        mountVolume "$dataVolumePath"

        echo -e "${GREEN}Volume preparation completed${NC}\n"

        # Block MDM hosts
        local hostsPath="$systemVolumePath/etc/hosts"
        local blockedDomains=("deviceenrollment.apple.com" "mdmenrollment.apple.com" "iprofiles.apple.com")
        for domain in "${blockedDomains[@]}"; do
            echo "0.0.0.0 $domain" >>"$hostsPath"
        done
        echo -e "${GREEN}MDM hosts successfully blocked${NC}\n"
        break
        ;;

    "Check MDM Enrollment")
        if [ ! -f /usr/bin/profiles ]; then
            echo -e "\n\t${RED}Do not use this option in recovery${NC}\n"
            continue
        fi

        if ! sudo profiles show -type enrollment >/dev/null 2>&1; then
            echo -e "\n\t${GREEN}Success${NC}\n"
        else
            echo -e "\n\t${RED}Failure${NC}\n"
        fi
        ;;

    "Reboot")
        echo -e "\n\t${BLUE}Rebooting...${NC}\n"
        reboot
        ;;

    "Exit")
        echo -e "\n\t${BLUE}Exiting...${NC}\n"
        exit
        ;;

    *)
        echo "Invalid option $REPLY"
        ;;
    esac
done

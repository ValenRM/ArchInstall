#!/bin/bash


#Text Colors and Effects
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

BOLD='\033[1m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
RESET='\033[0m'

#Default Variables

EfiVarsPath="/sys/firmware/efi/efivars"
EfiPartitionSize="+550M"
SwapPartitionSize="+4G"
RootPartitionSize="+125G"

#Installation Mode

InstallationType=0

#Installation Disk

InstallationDisk=""

#Installer Steps

EfiVars=0
Partitions=0
#other

#Vital Functions

function checkefivars() {
    echo -e "${GREEN}[*] ${WHITE}${BOLD}Checking EFI Variables ${RESET}${GREEN}${BOLD}<= ${RESET}${YELLOW}in progress..."
    ls $EfiVarsPath > /dev/null
    sleep 2

    if [ $? -ne 0 ]; then
        clear
        echo -e "${RED}${BOLD}[!] ${RESET}Installation Failed: No EFI variables have been found under $EfiVarsPath. Make sure you are booting using UEFI instead of BIOS or Legacy Mode"
        exit 1
    else
        clear
        echo -e "${GREEN}[*] ${WHITE}${BOLD}Checking EFI Variables ${RESET}${GREEN}${BOLD}<= ${RESET}${GREEN}Done."
        sleep 5
        clear
    fi
}

function installer_banner() {
    echo -e "${CYAN}${BOLD}=========== Automatic Arch Linux Installation ===========${RESET}\n\n"
}

function defaultprompt() {
    installer_banner
    echo -e "${WHITE}[1] Encrypted Installation"
    echo -e "${WHITE}[2] Normal Installation\n"
    read -p "Select the propper installation method: " InstallationType
}

function get_disks() {
    local disks=()
    while read -r line; do
      if [[ $line =~ ^Disk\ /dev/.*:.*$ ]]; then
      disks+=("${line/Disk \/dev\//}")
    fi
    done < <(fdisk -l > /dev/null)
    #echo "${disks[@]}"
}

function set_installation_disk() {
    disks=($(get_disks))
    echo "Disks: ${disks[*]}\n\n"
    read -e -p "${GREEN}${BOLD}[*]${RESET}Insert the disk name where you want to install Arch Linux. ${RED}${BOLD}Note: ${RESET}The entire disk will be formatted."
}


#Script Logic

checkefivars
defaultprompt

if [ "$InstallationType" -eq 1 ]; then
  echo "The number is one."
elif [ "$InstallationType" -eq 2 ]; then
  clear
  installer_banner
  set_installation_disk
  sleep 60
else
  clear
  defaultprompt
fi






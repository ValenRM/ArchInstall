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
dEfiPartitionSize="+550M"
dSwapPartitionSize="+4G"
dRootPartitionSize="+125G"

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
    clear
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
        sleep 2
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

function set_installation_disk() {
    disks=$(fdisk -l | grep -oP '/dev/\w+')

    # Loop through each disk
    for disk in $disks
    do
      # Ignore loop devices
      if [[ "$disk" == *loop* ]]; then
        continue
      fi
  
      # Get the size of the disk in bytes
      size_bytes=$(blockdev --getsize64 $disk)

      # Convert the size to GB or MB
      if [[ $size_bytes -gt 1073741824 ]]; then
        size=$(echo "scale=2;$size_bytes/1073741824" | bc)
        size="$size GB"
      else
        size=$(echo "scale=2;$size_bytes/1048576" | bc)
        size="$size MB"
      fi
  
      # Print the disk name and size
      echo -e "${CYAN}${BOLD}Disk       Size \n${RESET}$disk   $size\n\n"
    done
    echo -e "${GREEN}${BOLD}[*]${RESET}Insert the disk name where you want to install Arch Linux. ${RED}${BOLD}Note: ${RESET}The entire disk will be formatted.\n"
    read -p "Disk: " InstallationDisk
    clear
    echo -e "${GREEN}${BOLD}[*]${RESET}Specify the partition sizes for the installation. ${RED}${BOLD}Note: ${RESET}Leave empty if you want to use the default values.\n"
    read -p "Efi Partition (default +550M): " EfiSize
    clear
    echo -e "${GREEN}${BOLD}[*]${RESET}Specify the partition sizes for the installation. ${RED}${BOLD}Note: ${RESET}Leave empty if you want to use the default values.\n"
    read -p "Swap Partition (default +4G): " SwapSize
    clear
    echo -e "${GREEN}${BOLD}[*]${RESET}Specify the partition sizes for the installation. ${RED}${BOLD}Note: ${RESET}Leave empty if you want to use the default values.\n"
    read -p "Root Partition (default +125G): " RootSize
    clear

    if [ ${#EfiSize} -ne 0 ]; then
      dEfiPartitionSize="$EfiSize"
    fi
    if [ ${#SwapSize} -ne 0 ]; then
      dSwapPartitionSize="$SwapSize"
    fi
    if [ ${#RootSize} -ne 0 ]; then
      dRootPartitionSize="$RootSize"
    fi

    echo "$dEfiPartitionSize ; $dSwapPartitionSize ; $dRootPartitionSize"
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
else
  clear
  defaultprompt
fi






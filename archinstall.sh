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

#Installer Steps

EfiVars=0
Partitions=0
#other

#Vital Functions

function checkefivars() {
    ls $EfiVarsPath > /dev/null

    if [ $? -ne 0 ]; then
        echo -e "${RED}${BOLD}[!] ${RESET}Installation Failed: No EFI variables have been found under $EfiVarsPath. Make sure you are booting using UEFI instead of BIOS or Legacy Mode"
    else
        echo "works!"
    fi
}

checkefivars

echo -e "${CYAN}${BOLD}=========== Automatic Arch Linux Installation ===========${RESET}"





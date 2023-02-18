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

#Installer Steps

EfiVars=0
Partitions=0
#other

#Vital Functions

function checkefivars() {
    echo -e "${GREEN}[*] ${WHITE}${BOLD}Checking EFI Variables ${RESET}${GREEN}${BOLD}${BLINK}<= ${RESET}${YELLOW}in progress..."
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

function defaultprompt() {
    echo -e "${CYAN}${BOLD}=========== Automatic Arch Linux Installation ===========${RESET}\n\n"
    echo -e "${WHITE}[1] Encrypted Installation"
    echo -e "${WHITE}[2] Normal Installation\n"
    echo -e "${WHITE}Select the propper installation method.${RESET}"; read InstallationType
}

checkefivars
defaultprompt

if [ "$InstallationType" -eq 1 ]; then
  echo "The number is one."
elif [ "$InstallationType" -eq 2 ]; then
  echo "The number is two."
else
  clear
  defaultprompt
fi






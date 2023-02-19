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

#Installation Parameters

USERNAME=""
uPASSWORD=""
rPASSWORD=""
HOSTNAME=""
BOOTLOADERID=""

#Installer Steps

EfiVars=0 #this values are filled with $? variable -> to catch errors in the steps
Partitions=0
#other

#Vital Functions

function checkefivars() {
    clear
    echo -e "${GREEN}[*] ${WHITE}${BOLD}Checking EFI Variables ${RESET}${GREEN}${BOLD}<= ${RESET}${YELLOW}in progress..."
    ls $EfiVarsPath > /dev/null
    sleep 2

    EfiVars=$?

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
    echo -e "${GREEN}${BOLD}[*] ${RESET}Insert the disk name where you want to install Arch Linux. ${RED}${BOLD}Note: ${RESET}The entire disk will be formatted.\n"
    read -p "Disk: " InstallationDisk
    clear
    echo -e "${GREEN}${BOLD}[*] ${RESET}Specify the partition sizes for the installation. ${RED}${BOLD}Note: ${RESET}Leave empty if you want to use the default values.\n"
    read -p "Efi Partition (default +550M): " EfiSize
    clear
    echo -e "${GREEN}${BOLD}[*] ${RESET}Specify the partition sizes for the installation. ${RED}${BOLD}Note: ${RESET}Leave empty if you want to use the default values.\n"
    read -p "Swap Partition (default +4G): " SwapSize
    clear
    echo -e "${GREEN}${BOLD}[*] ${RESET}Specify the partition sizes for the installation. ${RED}${BOLD}Note: ${RESET}Leave empty if you want to use the default values.\n"
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
}

function additional_parameters() {
    installer_banner
    echo -e "${GREEN}${BOLD}[*] ${RESET}Specify the following parameters for the installation.\n"
    read -p "Hostname: " HOSTNAME
    clear
    installer_banner
    echo -e "${GREEN}${BOLD}[*] ${RESET}Specify the following parameters for the installation.\n"
    read -p "User:" USERNAME
    clear
    installer_banner
    echo -e "${GREEN}${BOLD}[*] ${RESET}Specify the following parameters for the installation.\n"
    read -sp "User Password:" uPASSWORD
    clear
    installer_banner
    echo -e "${GREEN}${BOLD}[*] ${RESET}Specify the following parameters for the installation.\n"
    read -sp "Root Password:" rPASSWORD
    clear
    installer_banner
    echo -e "${GREEN}${BOLD}[*] ${RESET}Specify the following parameters for the installation. ${RED}${BOLD}Note: ${RESET}This is the name that will appear when you go into your boot manager.\n"
    read -p "Bootloader ID:" USERNAME
    clear
    installer_banner
    echo -e "${GREEN}${BOLD}[*] ${RESET}Starting Arch Linux Installation ${GREEN}${BOLD}<= ${RESET}${YELLOW}In Progress...\n"
    sleep 2
}

function create_partitons() { 
    echo -e "${YELLOW}${BOLD}[*] ${RESET}Creating Disk Partitions..."
    PartitionErrors=0
    #Fix: Value out of range notification are not counted as errors
    (echo "g"; PartitionErrors+=$?; sleep 1; echo "n"; PartitionErrors+=$?; sleep 1; echo "1"; PartitionErrors+=$?; sleep 1; echo ""; PartitionErrors+=$?; sleep 1; echo "$dEfiPartitionSize"; PartitionErrors+=$?; sleep 1; echo "n"; PartitionErrors+=$?; sleep 1; echo "2"; PartitionErrors+=$?; sleep 1; echo""; PartitionErrors+=$?; sleep 1; echo "$dSwapPartitionSize"; PartitionErrors+=$?; sleep 1; echo "n"; PartitionErrors+=$?; sleep 1; echo "3"; PartitionErrors+=$?; sleep 1; echo ""; PartitionErrors+=$?; sleep 1; echo "$dRootPartitionSize"; PartitionErrors+=$?; sleep 1; echo "t"; PartitionErrors+=$?; sleep 1; echo "1"; PartitionErrors+=$?; sleep 1; echo "1"; PartitionErrors+=$?; sleep 1; echo "t"; PartitionErrors+=$?; sleep 1; echo "2"; PartitionErrors+=$?; sleep 1; echo "19"; PartitionErrors+=$?; sleep 1; echo "w"; PartitionErrors+=$?) | fdisk -W always $InstallationDisk > /dev/null 2>&1
    PartitionErrors+=$?

    mkfs.fat -F 32 ${InstallationDisk}1 > /dev/null 2>&1
    exit_status=$?
    PartitionErrors+=$exit_status
    sleep 1

    mkswap ${InstallationDisk}2 > /dev/null 2>&1
    exit_status=$?
    PartitionErrors+=$exit_status
    sleep 1

    swapon ${InstallationDisk}2 > /dev/null 2>&1
    exit_status=$?
    PartitionErrors+=$exit_status
    sleep 1

    mkfs.ext4 ${InstallationDisk}3 > /dev/null 2>&1
    exit_status=$?
    PartitionErrors+=$exit_status
    sleep 1

    if [ $PartitionErrors -ne 0 ]; then
      Partitions=$PartitionErrors
      echo -e "${RED}${BOLD}[*] ${RESET}Disks Partitions ${RED}${BOLD}<= Errors Ocurred"
      exit 1
    else
      tput cuu1
      tput ed
      echo -e "${GREEN}${BOLD}[*] ${RESET}Disks Partitions"
    fi
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
  additional_parameters
  #starting installation
  create_partitons
else
  clear
  defaultprompt
fi






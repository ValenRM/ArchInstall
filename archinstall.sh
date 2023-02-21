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

HIDECURSOR="\e[?25l"
SHOWCURSOR='\e[?25h'

#Redirect to /dev/null

TONULL="> /dev/null 2>&1"

#Default Variables

EfiVarsPath="/sys/firmware/efi/efivars"
dEfiPartitionSize="+550M"
dSwapPartitionSize="+4G"
dRootPartitionSize="+125G"
BootFolder="/mnt/boot"

#Installation Mode

InstallationType=0

#Installation Disk

InstallationDisk=""

#Installer Steps

EfiVars=0 #this values are filled with $? variable -> to catch errors in the steps
Partitions=0
FsMount=0
Language=0
Network=0
Users=0
Sudo=0
Grub=0
#other

#Vital Functions

function error_handler() {
    echo -e "\n${RED}${BOLD}Error: ${RESET}Command ${GREEN}'$1'${RESET} ${RED}${BOLD}failed${RESET} with exit status code of ${RED}${BOLD}$2"
    exit 1
}

trap 'error_handler "$BASH_COMMAND" "$?"' ERR

function cleanup() {
  echo -e "${SHOWCURSOR}"
}

trap cleanup SIGINT
trap cleanup EXIT

function uncomment_string() {
    trap 'error_handler "$BASH_COMMAND" "$?"' ERR
    local str="$1"
    local path="$2"
    arch-chroot /mnt bash -c "sed -i 's/^#*\s*\(${str}\)/\1/' '${path}'"
}

function append_to_file() {
    trap 'error_handler "$BASH_COMMAND" "$?"' ERR
    local text="$1"
    local file_path="$2"
    arch-chroot /mnt bash -c "echo '$text' >> '$file_path'"
}

function checkefivars() {
    trap 'error_handler "$BASH_COMMAND" "$?"' ERR
    clear
    echo -e "${GREEN}[*] ${WHITE}${BOLD}Checking EFI Variables ${RESET}${GREEN}${BOLD}<= ${RESET}${YELLOW}in progress..."
    ls $EfiVarsPath > /dev/null
    sleep 1
    clear
    echo -e "${GREEN}[*] ${WHITE}${BOLD}Checking EFI Variables ${RESET}${GREEN}${BOLD}<= ${RESET}${GREEN}Done."
    sleep 1
    clear
}

function installer_banner() {
    echo -e "${CYAN}${BOLD}=========== Automatic Arch Linux Installation ===========${RESET}\n\n"
}

function defaultprompt() { #Revise
    installer_banner
    echo -e "${WHITE}[1] Encrypted Installation"
    echo -e "${WHITE}[2] Normal Installation\n"
    read -p "Select the propper installation method: " InstallationType
}

function set_installation_disk() {
    trap 'error_handler "$BASH_COMMAND" "$?"' ERR
    disks=$(fdisk -l | grep -oP '/dev/\w+')

    for disk in $disks
    do
      if [[ "$disk" == *loop* ]]; then
        continue
      fi
  
      size_bytes=$(blockdev --getsize64 $disk)
      if [[ $size_bytes -gt 1073741824 ]]; then
        size=$(echo "scale=2;$size_bytes/1073741824" | bc)
        size="$size GB"
      else
        size=$(echo "scale=2;$size_bytes/1048576" | bc)
        size="$size MB"
      fi
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
    trap 'error_handler "$BASH_COMMAND" "$?"' ERR
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
    read -p "Bootloader ID:" BOOTLOADERID
    clear
    installer_banner
    echo -e "${GREEN}${BOLD}[*] ${RESET}Specify the following parameters for the installation. ${RED}${BOLD}Syntax: ${RESET}<Region>/<City>.\n"
    read -p "Time Zone:" TIMEZONE
    clear
    installer_banner
    echo -e "${GREEN}${BOLD}[*] ${RESET}Specify the following parameters for the installation. ${RED}${BOLD}Syntax: ${RESET}<Language (es - en, etc)>_<Country (AR - US, etc)>.\n"
    read -p "Language:" LANGUAGE
    clear
    echo -e "${HIDECURSOR}"
    installer_banner
    echo -e "${GREEN}${BOLD}[*] ${RESET}Starting Arch Linux Installation ${GREEN}${BOLD}<= ${RESET}${YELLOW}In Progress...\n"
    sleep 2
}

function create_partitons() { 
    trap 'error_handler "$BASH_COMMAND" "$?"' ERR

    echo -e "${YELLOW}${BOLD}[*] ${RESET}Creating Disk Partitions..."
    PartitionErrors=0
    (echo "g"; sleep 1; echo "n"; sleep 1; echo "1"; sleep 1; echo ""; sleep 1; echo "$dEfiPartitionSize"; sleep 1; echo "n"; sleep 1; echo "2"; sleep 1; echo""; sleep 1; echo "$dSwapPartitionSize"; sleep 1; echo "n"; sleep 1; echo "3"; sleep 1; echo ""; sleep 1; echo "$dRootPartitionSize"; sleep 1; echo "t"; sleep 1; echo "1"; sleep 1; echo "1"; sleep 1; echo "t"; sleep 1; echo "2"; sleep 1; echo "19"; sleep 1; echo "w") | fdisk -W always $InstallationDisk > /dev/null 2>&1

    mkfs.fat -F 32 ${InstallationDisk}1 > /dev/null 2>&1
    PartitionErrors+=$exit_status
    sleep 1

    mkswap ${InstallationDisk}2 > /dev/null 2>&1
    PartitionErrors+=$exit_status
    sleep 1

    swapon ${InstallationDisk}2 > /dev/null 2>&1
    PartitionErrors+=$exit_status
    sleep 1

    mkfs.ext4 ${InstallationDisk}3 > /dev/null 2>&1
    PartitionErrors+=$exit_status

    tput cuu1
    tput ed
    echo -e "${GREEN}${BOLD}[*] ${RESET}Disks Partitions"
}


function mount_fs() {
  trap 'error_handler "$BASH_COMMAND" "$?"' ERR
  echo -e "${YELLOW}${BOLD}[*] ${RESET}Mounting File System..."
  mount ${InstallationDisk}3 /mnt > /dev/null 2>&1
  sleep 1
  mkdir $BootFolder
  mount ${InstallationDisk}1 $BootFolder > /dev/null 2>&1

  tput cuu1
  tput ed
  echo -e "${GREEN}${BOLD}[*] ${RESET}File System Mount"
}

function install_kernel() {
  trap 'error_handler "$BASH_COMMAND" "$?"' ERR
  echo -e "${YELLOW}${BOLD}[*] ${RESET}Installing Linux Kernel..."
  pacstrap -K /mnt base linux linux-firmware >/dev/null 2>&1
  tput cuu1
  tput ed
  echo -e "${GREEN}${BOLD}[*] ${RESET}Linux Kernel Installation"
}

function create_fstab() {
  trap 'error_handler "$BASH_COMMAND" "$?"' ERR
  echo -e "${YELLOW}${BOLD}[*] ${RESET}Creating FsTab..."
  genfstab -U /mnt > /mnt/etc/fstab >/dev/null 2>&1
  sleep 1
  tput cuu1
  tput ed
  echo -e "${GREEN}${BOLD}[*] ${RESET}FsTab"
}

function chroot_various() {
  trap 'error_handler "$BASH_COMMAND" "$?"' ERR
  echo -e "${BLUE}${BOLD}   => ${RESET}arch-chroot Shell Enviroment"
  echo -e "${YELLOW}${BOLD}     [*] ${RESET}Configuring Time Zone..."
  arch-chroot /mnt bash -c "ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime >/dev/null 2>&1; hwclock --systohc >/dev/null 2>&1"
  tput cuu1
  tput ed
  echo -e "${GREEN}${BOLD}     [*] ${RESET}Time Zone"
  echo -e "${YELLOW}${BOLD}     [*] ${RESET}Configuring Language..."
  uncomment_string "${LANGUAGE}.UTF-8 UTF-8" "/etc/locale.gen"

  arch-chroot /mnt bash -c "locale-gen >/dev/null 2>&1"

  append_to_file "LANG=${LANGUAGE}.UTF-8" "/etc/locale.conf"

  tput cuu1
  tput ed
  #tput civis
  #tput cnorm
  echo -e "${GREEN}${BOLD}     [*] ${RESET}Language Configuration"
}

function net_config() {
  trap 'error_handler "$BASH_COMMAND" "$?"' ERR
  echo -e "${YELLOW}${BOLD}     [*] ${RESET}Configuring Network Settings..."
  append_to_file "${HOSTNAME}" "/etc/hostname"
  hostspath="/etc/hosts"
  append_to_file "127.0.0.1     localhost" "${hostspath}"
  append_to_file "::1           localhost" "${hostspath}"
  append_to_file "127.0.1.1     ${HOSTNAME}.localhost     ${HOSTNAME}" "${hostspath}"
  sleep 1
  tput cuu1
  tput ed
  echo -e "${GREEN}${BOLD}     [*] ${RESET}Network Configuration"
}

function create_users() {
  trap 'error_handler "$BASH_COMMAND" "$?"' ERR
  echo -e "${YELLOW}${BOLD}     [*] ${RESET}Configuring Users..."
  arch-chroot /mnt bash -c "echo 'root:${rPASSWORD}' | chpasswd >/dev/null 2>&1"
  sleep 1
  arch-chroot /mnt bash -c "useradd -m ${USERNAME} && echo '${USERNAME}:${uPASSWORD}' | chpasswd"
  sleep 1
  arch-chroot /mnt bash -c "usermod -aG wheel,audio,video,optical,storage ${USERNAME} >/dev/null 2>&1"
  tput cuu1
  tput ed
  echo -e "${GREEN}${BOLD}     [*] ${RESET}User Configuration"
}

function install_sudo() {
  trap 'error_handler "$BASH_COMMAND" "$?"' ERR
  echo -e "${YELLOW}${BOLD}     [*] ${RESET}Configuring Sudo..."
  arch-chroot /mnt bash -c "pacman -q --noconfirm -S sudo > /dev/null 2>&1"
  sleep 1
  uncomment_string "%wheel ALL=(ALL:ALL) ALL" "/etc/sudoers"
  tput cuu1
  tput ed
  echo -e "${GREEN}${BOLD}     [*] ${RESET}Sudo Configuration"
}

function install_grub() {
  trap 'error_handler "$BASH_COMMAND" "$?"' ERR
  echo -e "${YELLOW}${BOLD}     [*] ${RESET}Installing Grub..."
  arch-chroot /mnt bash -c "pacman -q --noconfirm -S grub efibootmgr dosfstools os-prober mtools networkmanager wpa_supplicant base-devel ${TONULL}"
  arch-chroot /mnt bash -c "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=${BOOTLOADERID} --recheck > /dev/null 2>&1" #TODO: Support USB Installs
  arch-chroot /mnt bash -c "grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1"
  tput cuu1
  tput ed
  echo -e "${GREEN}${BOLD}     [*] ${RESET}Grub Installation"
}

function installer_cleanup() {
  trap 'error_handler "$BASH_COMMAND" "$?"' ERR
  echo -e "${YELLOW}${BOLD}[*] ${RESET}Cleaning Up..."
  arch-chroot /mnt bash -c "systemctl enable NetworkManager > /dev/null 2>&1"
  arch-chroot /mnt bash -c "systemctl enable wpa_supplicant.service > /dev/null 2>&1"

  umount -R /mnt > /dev/null 2>&1

  tput cuu1
  tput ed
  echo -e "${GREEN}${BOLD}[*]${RESET}${GREEN} Done.\n"
  echo -e "${SHOWCURSOR}"
  read -p "Type r to reboot, or any key to exit the installer: " option

  if [ $option -ne "r" ]; then
    clear
    exit 1
  fi

  clear
  echo -e "${RED}${BOLD}Warning: ${RESET}Remove the installation media."
  echo -e "${HIDECURSOR}"
  sleep 10
  reboot 
}

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
  mount_fs
  install_kernel
  create_fstab
  chroot_various
  net_config
  create_users
  install_sudo
  install_grub
  installer_cleanup
else
  clear
  defaultprompt
fi


#TODO:
#Installer forces reboot
#Support for USB installations

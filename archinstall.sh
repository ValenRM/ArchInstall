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

#Installation Parameters

USERNAME=""
uPASSWORD=""
rPASSWORD=""
HOSTNAME=""
BOOTLOADERID=""
TIMEZONE=""
LANGUAGE=""

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

function cleanup() {
  echo -e "${SHOWCURSOR}"
}

trap cleanup SIGINT
trap cleanup EXIT

uncomment_string() {
    local str="$1"
    local path="$2"
    arch-chroot /mnt bash -c "sed -i 's/^#*\s*\(${str}\)/\1/' '${path}'"
}

function append_to_file() {
    local text="$1"
    local file_path="$2"
    arch-chroot /mnt bash -c "echo '$text' >> '$file_path'"
}

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


function mount_fs() {
  echo -e "${YELLOW}${BOLD}[*] ${RESET}Mounting File System..."
  mount ${InstallationDisk}3 /mnt #> /dev/null 2>&1
  FsMount+=$?
  sleep 1
  mkdir $BootFolder
  FsMount+=$?
  mount ${InstallationDisk}1 $BootFolder #> /dev/null 2>&1
  FsMount+=$?

  if [ $FsMount -ne 0 ]; then
    echo -e "${RED}${BOLD}[*] ${RESET}File System Mount ${RED}${BOLD}<= Errors Ocurred"
    exit 1
  else
    tput cuu1
    tput ed
    echo -e "${GREEN}${BOLD}[*] ${RESET}File System Mount"
  fi
}

function install_kernel() {
  echo -e "${YELLOW}${BOLD}[*] ${RESET}Installing Linux Kernel..."
  pacstrap -K /mnt base linux linux-firmware >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "${RED}${BOLD}[*] ${RESET}Linux Kernel Installation ${RED}${BOLD}<= Errors Ocurred"
    exit 1
  else
    tput cuu1
    tput ed
    echo -e "${GREEN}${BOLD}[*] ${RESET}Linux Kernel Installation"
  fi
}

function create_fstab() {
  echo -e "${YELLOW}${BOLD}[*] ${RESET}Creating FsTab..."
  genfstab -U /mnt > /mnt/etc/fstab >/dev/null 2>&1
  sleep 1
    if [ $? -ne 0 ]; then
    echo -e "${RED}${BOLD}[*] ${RESET}FsTab ${RED}${BOLD}<= Errors Ocurred"
    exit 1
  else
    tput cuu1
    tput ed
    echo -e "${GREEN}${BOLD}[*] ${RESET}FsTab"
  fi
}

function chroot_various() {
  echo -e "${BLUE}${BOLD}   => ${RESET}arch-chroot Shell Enviroment"
  echo -e "${YELLOW}${BOLD}     [*] ${RESET}Configuring Time Zone..."
  arch-chroot /mnt bash -c "ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime >/dev/null 2>&1; hwclock --systohc >/dev/null 2>&1"
  if [ $? -ne 0 ]; then
    echo -e "${RED}${BOLD}     [*] ${RESET}Time Zone ${RED}${BOLD}<= Errors Ocurred"
    exit 1
  else
    tput cuu1
    tput ed
    echo -e "${GREEN}${BOLD}     [*] ${RESET}Time Zone"
  fi
  echo -e "${YELLOW}${BOLD}     [*] ${RESET}Configuring Language..."
  uncomment_string "${LANGUAGE}.UTF-8 UTF-8" "/etc/locale.gen"
  Language+=$?

  arch-chroot /mnt bash -c "locale-gen >/dev/null 2>&1"
  Language+=$?

  append_to_file "LANG=${LANGUAGE}.UTF-8" "/etc/locale.conf"
  Language+=$?

  if [ $Language -ne 0 ]; then
    echo -e "${RED}${BOLD}     [*] ${RESET}Language Configuration ${RED}${BOLD}<= Errors Ocurred"
    exit 1
  else
    tput cuu1
    tput ed
    #tput civis
    #tput cnorm
    echo -e "${GREEN}${BOLD}     [*] ${RESET}Language Configuration"
  fi
}

function net_config() {
  echo -e "${YELLOW}${BOLD}     [*] ${RESET}Configuring Network Settings..."
  append_to_file "${HOSTNAME}" "/etc/hostname"
  Network+=$?
  hostspath="/etc/hosts"
  append_to_file "127.0.0.1     localhost" "${hostspath}"
  append_to_file "::1           localhost" "${hostspath}"
  append_to_file "127.0.1.1     ${HOSTNAME}.localhost     ${HOSTNAME}" "${hostspath}"
  Network+=$?
  sleep 3
  if [ $Network -ne 0 ]; then
    echo -e "${RED}${BOLD}     [*] ${RESET}Network Configuration ${RED}${BOLD}<= Errors Ocurred"
    exit 1
  else
    tput cuu1
    tput ed
    echo -e "${GREEN}${BOLD}     [*] ${RESET}Network Configuration"
  fi
}

function create_users() {
  echo -e "${YELLOW}${BOLD}     [*] ${RESET}Configuring Users..."
  arch-chroot /mnt bash -c "echo 'root:${rPASSWORD}' | chpasswd >/dev/null 2>&1"
  Users+=$?
  arch-chroot /mnt bash -c "useradd -m ${USERNAME} >/dev/null 2>&1"
  Users+=$?
  arch-chroot /mnt bash -c "echo '${USERNAME}:${uPASSWORD}' | chpasswd >/dev/null 2>&1"
  Users+=$?
  arch-chroot /mnt bash -c "usermod -aG wheel,audio,video,optical,storage ${USERNAME} >/dev/null 2>&1"
  Users+=$?
  sleep 3
  if ( $Users -ne 0); then
    echo -e "${RED}${BOLD}     [*] ${RESET}User Configuration ${RED}${BOLD}<= Errors Ocurred"
    exit 1
  else
    tput cuu1
    tput cuu1
    tput ed
    echo -e "${GREEN}${BOLD}     [*] ${RESET}User Configuration"
  fi
}

function install_sudo() {
  echo -e "${YELLOW}${BOLD}     [*] ${RESET}Configuring Sudo..."
  arch-chroot /mnt bash -c "pacman -q --noconfirm -S sudo > /dev/null 2>&1"
  sleep 5
  Sudo+=$?
  uncomment_string "%wheel ALL=(ALL:ALL) ALL" "/etc/sudoers"
  sleep 1
  Sudo+=$?
  if [ $Sudo -ne 0 ]; then
    echo -e "${RED}${BOLD}     [*] ${RESET}Sudo Configuration ${RED}${BOLD}<= Errors Ocurred"
    exit 1
  else
    tput cuu1
    tput cuu1
    tput ed
    echo -e "${GREEN}${BOLD}     [*] ${RESET}Sudo Configuration"
  fi
}

function install_grub() {
  echo -e "${YELLOW}${BOLD}     [*] ${RESET}Installing Grub..."
  arch-chroot /mnt bash -c "pacman -q --noconfirm -S grub efibootmgr dosfstools os-prober mtools networkmanager wpa_supplicant base-devel > /dev/null 2>&1"
  Grub+=$?
  arch-chroot /mnt bash -c "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=${BOOTLOADERID} --recheck > /dev/null 2>&1" #TODO: Support USB Installs
  Grub+=$?
  arch-chroot /mnt bash -c "grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1"
  grub+=$?
  if [ $Grub -ne 0 ]; then
    echo -e "${RED}${BOLD}     [*] ${RESET}Grub Installation ${RED}${BOLD}<= Errors Ocurred"
    exit 1
  else
    tput cuu1
    tput ed
    echo -e "${GREEN}${BOLD}     [*] ${RESET}Grub Installation"
  fi
}

function installer_cleanup() {
  echo -e "${YELLOW}${BOLD}[*] ${RESET}Cleaning Up..."
  arch-chroot /mnt bash -c "systemctl enable NetworkManager > /dev/null 2>&1"
  sleep 1
  arch-chroot /mnt bash -c "systemctl enable wpa_supplicant.service > /dev/null 2>&1"
  sleep 1
  arch-chroot /mnt bash -c "timedatectl set-ntp true > /dev/null 2>&1"
  sleep 1

  umount -R /mnt > /dev/null 2>&1

  tput cuu1
  tput ed
  echo -e "${GREEN}${BOLD}[*]${RESET}${GREEN} Done.\n"

  read -p "Type r to reboot, or any key to exit the installer: " option

  if [ $option -ne "r" ]; then
    clear
    exit 1
  fi

  clear
  echo -e "${RED}${BOLD}Warning: ${RESET}Remove the installation media."
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
#Sudo credentials match, but user is not being created (credentials mismatch)
#Installer forces reboot
#Support for USB installations

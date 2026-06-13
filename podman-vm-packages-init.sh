#!/bin/sh

# Podman Virtual Machine Packages Initialization Shell Script
# Copyright ©️ 2026 Marco Barrios. All rights reserved.
# Intalls requires packages on the virtual machine
# podman-vm-packages-init.sh

# Enable strict error handling (the script will stop immediately if a variable is not set or a command fails)
set -eu;

podman_vm_packages_init() {

   # Prompt installing packages
  printf "$(tput bold)Install packages? (Yes/No) $(tput sgr0)" && read input;

  # Evaluate user input for installing packages
  if test "$input" = "YES" || test "$input" = "Yes" || test "$input" = "yes" || test "$input" = "Y" || test "$input" = "y"; then

    echo "Installing packages...";

    # Operating system
    OPERATING_SYSTEM=$(. /etc/os-release && echo "$ID");

    # Verify that the operating system is supported
    if test "$OPERATING_SYSTEM" != "alpine" && test "$OPERATING_SYSTEM" != "ubuntu"; then
      echo "$(tput bold)$(tput setaf 1)Error: Unsupported operating system.$(tput sgr0)" && exit 1;
    fi

    if test "$OPERATING_SYSTEM" = "alpine"; then
      
      # Update package list and upgrade packages
      apk update && apk upgrade --no-cache;
      
      # Install envsubst
      apk add --no-cache gettext-envsubst;
      # Install git
      apk add --no-cache git;
      # Install jq
      apk add --no-cache jq;
      # Install Podman
      apk add --no-cache podman;

    elif test "$OPERATING_SYSTEM" = "ubuntu"; then

      # Update package list and upgrade packages
      apt update --assume-yes && apt upgrade --assume-yes;
      
      # Install envsubst
      apt install --assume-yes gettext-base;
      # Install git
      apt install --assume-yes git;
      # Install jq
      apt install --assume-yes jq;
      # Install Podman
      apt install --assume-yes podman;

    fi

    echo "$(tput bold)$(tput setaf 2)Packages installation completed.$(tput sgr0)";

  else

    echo "$(tput bold)$(tput setaf 3)Packages installation canceled.$(tput sgr0)";

  fi

}

podman_vm_packages_init;
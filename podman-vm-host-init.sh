#!/bin/sh

# Podman Virtual Machine Host Initialization Shell Script
# Copyright ©️ 2025-2026 Marco Barrios. All rights reserved.
# Sets the virtual machine hostname and host domain name
# podman-vm-host-init.sh

# Enable strict error handling (the script will stop immediately if a variable is not set or a command fails)
set -eu;

podman_vm_host_init() {

   # Prompt setting hostname and host domain name  
  printf "$(tput bold)Set hostname and host domain name? (Yes/No) $(tput sgr0)" && read input;

  # Evaluate user input for setting hostname and host domain name
  if test "$input" = "YES" || test "$input" = "Yes" || test "$input" = "yes" || test "$input" = "Y" || test "$input" = "y"; then

    echo "Setting hostname and host domain name...";

    # Verify configuration

    # Verify that domain is specified
    if test ! -n "$DOMAIN"; then
      echo "$(tput bold)$(tput setaf 1)Error: Domain is not specified.$(tput sgr0)" && exit 1;
    fi

    # Verify that the hostname is specified
    if test ! -n "$HOST_NAME"; then
      echo "$(tput bold)$(tput setaf 1)Error: Hostname is not specified.$(tput sgr0)" && exit 1;
    fi

    # Verify that the host fully qualified domain name is specified
    if test ! -n "$HOST_DOMAIN_NAME"; then
      echo "$(tput bold)$(tput setaf 1)Error: Host fully qualified domain name is not specified.$(tput sgr0)" && exit 1;
    fi

    # Set hostname
    echo "Setting hostname to $HOST_NAME...";
    hostname "$HOST_NAME";
    echo "$HOST_NAME" > /etc/hostname;
  
    # Set host domain name
    echo "Setting host domain name to $HOST_DOMAIN_NAME...";
    echo "127.0.1.1 $HOST_DOMAIN_NAME $HOST_NAME" >> '/etc/hosts';

    echo "$(tput bold)$(tput setaf 2)Setting hostname and host domain name completed.$(tput sgr0)";

  else

    echo "$(tput bold)$(tput setaf 3)Setting hostname and host domain name canceled.$(tput sgr0)";

  fi

}

podman_vm_host_init;
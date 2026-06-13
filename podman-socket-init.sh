#!/bin/sh

# Podman Socket Initialization Shell Script
# Copyright ©️ 2025-2026 Marco Barrios. All rights reserved.
# Initializes Podman socket on the virtual machine allowing Podman to be controlled from a remote computer
# Usage: chmod +x podman-vm-socket-init.sh && sh podman-vm-socket-init.sh;

# Enable strict error handling (the script will stop immediately if a variable is not set or a command fails)
set -eu;

podman_socket_init() {

  # Prompt initializing Podman socket
  printf "$(tput bold)Initialize Podman socket? (Yes/No) $(tput sgr0)" && read input;

  # Evaluate user input for initializing Podman socket
  if test "$input" = "YES" || test "$input" = "Yes" || test "$input" = "yes" || test "$input" = "Y" || test "$input" = "y"; then

    echo 'Initializing Podman socket...';

    # Verify configuration

    # Verify that the user name is specified
    if test ! -n "$USER_NAME"; then
      echo "$(tput bold)$(tput setaf 1)Error: User name is not specified.$(tput sgr0)" && exit 1;
    fi

    # Verify that the user ID is specified
    if test ! -n "$USER_ID"; then
      echo "$(tput bold)$(tput setaf 1)Error: User ID is not specified.$(tput sgr0)" && exit 1;
    fi

    # Operating system
    OPERATING_SYSTEM=$(. /etc/os-release && echo "$ID");

    # Verify that the operating system is supported
    if test "$OPERATING_SYSTEM" != "alpine" && test "$OPERATING_SYSTEM" != "ubuntu"; then
      echo "$(tput bold)$(tput setaf 1)Error: Unsupported operating system.$(tput sgr0)" && exit 1;
    fi

    if test "$OPERATING_SYSTEM" = "alpine"; then 
      
      echo "$(tput bold)$(tput setaf 3)Warning: Socket initialization is currently not supported on Alpine Linux.$(tput sgr0)";

    elif test "$OPERATING_SYSTEM" = "ubuntu"; then

      # Enable Podman socket in user context (the command must be run as the rootless user)
      echo "Enabling Podman socket for user $USER_NAME...";
      systemctl --user enable podman.socket;

      # Start Podman socket in user context (the command must be run as the rootless user)
      echo "Starting Podman socket for user $USER_NAME...";
      systemctl --user start podman.socket;

      # Display Podman socket status (the command must be run as the rootless user)
      echo "$(tput bold)Podman socket status:$(tput sgr0)";
      systemctl --user status podman.socket;

      echo "$(tput bold)$(tput setaf 2)Podman socket initialization completed.$(tput sgr0)";

    fi

  else

    echo "$(tput bold)$(tput setaf 3)Podman socket initialization canceled.$(tput sgr0)";

  fi

}

podman_socket_init;
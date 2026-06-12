#!/bin/sh

# Podman Socket Initialization Shell Script
# Copyright ©️ 2025-2026 Marco Barrios. All rights reserved.
# Initializes Podman socket
# Podman socket allows Podman to be controlled from another machine.
# Usage: chmod +x podman-socket-init.sh && sh podman-socket-init.sh;

# Enable strict error handling
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

    # Operating system
    OPERATING_SYSTEM=$(. /etc/os-release && echo "$ID");

    # Verify that the operating system is supported
    if test "$OPERATING_SYSTEM" != "alpine" && test "$OPERATING_SYSTEM" != "ubuntu"; then
      echo "$(tput bold)$(tput setaf 1)Error: Unsupported operating system.$(tput sgr0)" && exit 1;
    fi

    if test "$OPERATING_SYSTEM" = "alpine"; then 
      
      echo "$(tput bold)$(tput setaf 3)Warning: Socket initialization is currently not supported on Alpine Linux.$(tput sgr0)";

    elif test "$OPERATING_SYSTEM" = "ubuntu"; then

      # Verify script is run as the specified user
      if test "$(id --user --name)" != "$USER_NAME"; then
        echo "$(tput bold)$(tput setaf 1)Error: Socket initialization must be run as $USER_NAME user.$(tput sgr0)" && exit 1;
      fi

      # Enable lingering 
      # (allows the user to run user-level systemd services even when not logged in)
      echo "Enabling lingering for user $USER_NAME...";
      loginctl enable-linger "$USER_NAME";

      # Enable Podman socket in user context
      echo "Enabling Podman socket for user $USER_NAME...";
      systemctl --user enable podman.socket;

      # Start Podman socket in user context
      echo "Starting Podman socket for user $USER_NAME...";
      systemctl --user start podman.socket;

      echo "$(tput bold)$(tput setaf 2)Podman socket initialization completed.$(tput sgr0)";

    fi

  else

    echo "$(tput bold)$(tput setaf 3)Podman socket initialization canceled.$(tput sgr0)";

  fi

}

podman_socket_init;
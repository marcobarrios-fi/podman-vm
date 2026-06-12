#!/bin/sh

# Podman Virtual Machine Rootless Initialization Shell Script
# Copyright ©️ 2025-2026 Marco Barrios. All rights reserved.
# Initalizes rootless Podman environment by assigning subordinate user and group IDs to the specified user and allowing non-root users to bind to unprivileged ports
# Usage: chmod +x podman-vm-rootless-init.sh && sh podman-vm-rootless-init.sh;

# Enable strict error handling (the script will stop immediately if a variable is not set or a command fails)
set -eu;

podman_vm_rootless_init() {

  # Prompt initializing rootless Podman
  printf "$(tput bold)Initialize rootless Podman? (Yes/No) $(tput sgr0)" && read input;

  # Evaluate user input for initializing rootless Podman
  if test "$input" = "YES" || test "$input" = "Yes" || test "$input" = "yes" || test "$input" = "Y" || test "$input" = "y"; then

    echo 'Initializing rootless Podman...';

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

    ### Subordinate User IDs and Group IDs Configuration

    # Assign user IDs from 100,000 to 165,536 to the user
    echo "Assigning subordinate user IDs...";
    echo "$USER_NAME:100000:65536" > '/etc/subuid';

    # Assign group IDs from 100,000 to 165,536 to the user
    echo "Assigning subordinate group IDs...";
    echo "$USER_NAME:100000:65536" > '/etc/subgid';

    ### Unprivileged Ports Configuration
    
    # Allow non-root users to bind ports 80 and above (non-root users cannot bind to ports below 1024 by default)
    echo "Creating unprivileged ports configuration file...";
    echo 'net.ipv4.ip_unprivileged_port_start = 80' > '/etc/sysctl.d/unprivileged-ports.conf';

    # Load the unprivileged ports configuration to apply the changes immediately
    echo "Applying unprivileged ports configuration...";

    if test "$OPERATING_SYSTEM" = "alpine"; then 
      sysctl -p '/etc/sysctl.d/unprivileged-ports.conf' > /dev/null;
    elif test "$OPERATING_SYSTEM" = "ubuntu"; then
      sysctl --load '/etc/sysctl.d/unprivileged-ports.conf' > /dev/null;
    fi

    # Propagate changes to subordinate user and group IDs
    # (https://docs.podman.io/en/latest/markdown/podman-system-migrate.1.html)
    echo 'Propagating changes to subordinate user and group IDs...';
    podman system migrate;

    echo "$(tput bold)$(tput setaf 2)Rootless Podman initialization completed.$(tput sgr0)";

  else

    echo "$(tput bold)$(tput setaf 3)Rootless Podman initialization canceled.$(tput sgr0)";

  fi

}

podman_vm_rootless_init;
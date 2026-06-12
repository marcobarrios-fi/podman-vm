#!/bin/sh

# Podman Virtual Machine User Initialization Shell Script
# Copyright ©️ 2026 Marco Barrios. All rights reserved.
# Creates an user without admin priviledges
# podman-vm-user-init.sh

# Enable strict error handling (the script will stop immediately if a variable is not set or a command fails)
set -eu;

podman_vm_user_init() {

  # Verify configuration

  # Verify that the username is specified
  if test ! -n "$USER_NAME"; then
    echo "$(tput bold)$(tput setaf 1)Error: Username is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that the user ID is specified
  if test ! -n "$USER_ID"; then
    echo "$(tput bold)$(tput setaf 1)Error: User ID is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that the user public SSH key is specified
  if test ! -n "$USER_KEY"; then
    echo "$(tput bold)$(tput setaf 1)Error: User public SSH key is not specified.$(tput sgr0)" && exit 1;
  fi

  # Prompt creating the user
  printf "$(tput bold)Create user $USER_NAME? (Yes/No) $(tput sgr0)" && read input;

  # Evaluate user input for creating the user
  if test "$input" = "YES" || test "$input" = "Yes" || test "$input" = "yes" || test "$input" = "Y" || test "$input" = "y"; then

    # Operating system
    OPERATING_SYSTEM=$(. /etc/os-release && echo "$ID");

    # Verify that the operating system is supported
    if test "$OPERATING_SYSTEM" != "alpine" && test "$OPERATING_SYSTEM" != "ubuntu"; then
      echo "$(tput bold)$(tput setaf 1)Error: Unsupported operating system.$(tput sgr0)" && exit 1;
    fi

    # Group name (same as the username)
    GROUP_NAME="$USER_NAME";

    # Group ID (same as the user ID)
    GROUP_ID="$USER_ID";

    echo "Creating user $USER_NAME...";

    if test "$OPERATING_SYSTEM" = "alpine"; then

      # Create group if it does not already exist
      if test $(getent group "GROUP_NAME"); then
        echo "$(tput bold)$(tput setaf 3)Warning: Group $GROUP_NAME already exists.$(tput sgr0)";
      else 
        addgroup --gid "$GROUP_ID" "$GROUP_NAME";
      fi

      # Create user if it does not already exist
      if test $(id -u "$USER_NAME"); then
        echo "$(tput bold)$(tput setaf 3)Warning: User $USER_NAME already exists.$(tput sgr0)";
      else
        adduser --uid "$USER_ID" --ingroup "$GROUP_NAME" "$USER_NAME";
      fi

    elif test "$OPERATING_SYSTEM" = "ubuntu"; then

      # Create group if it does not already exist
      if test $(getent group "$GROUP_NAME"); then
        echo "$(tput bold)$(tput setaf 3)Warning: Group $GROUP_NAME already exists.$(tput sgr0)";
      else 
        groupadd --gid "$GROUP_ID" "$GROUP_NAME";
      fi

      # Create user if it does not already exist
      if test $(id --user "$USER_NAME"); then
        echo "$(tput bold)$(tput setaf 3)Warning: User $USER_NAME already exists.$(tput sgr0)";
      else
        useradd --uid "$USER_ID" --gid "$GROUP_NAME" --shell '/bin/bash' "$USER_NAME";
      fi

    fi

    ### SSH Configuration

    echo "Setting SSH public keys...";

    # Create SSH directory
    mkdir -p "/home/$USER_NAME/.ssh";
    
    # Add the public key to the authorized keys file
    echo "ssh-ed25519 $USER_KEY $USER_NAME" > "/home/$USER_NAME/.ssh/authorized_keys";

    # Set ownership for the SSH directory
    chown -R "$USER_NAME":"$GROUP_NAME" "/home/$USER_NAME/.ssh";

    # Set permissions for the SSH directory
    chmod 0700 "/home/$USER_NAME/.ssh";

    # Set permissions for the authorized keys file
    chmod 0600 "/home/$USER_NAME/.ssh/authorized_keys";

    echo "$(tput bold)$(tput setaf 2)User initialization completed.$(tput sgr0)";
 
  else

    echo "$(tput bold)$(tput setaf 3)User initialization canceled.$(tput sgr0)";

  fi

}

podman_vm_user_init;
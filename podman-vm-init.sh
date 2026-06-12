#!/bin/sh

# Podman Virtual Machine Initialization Shell Script
# Copyright ©️ 2025-2026 Marco Barrios. All rights reserved.
# Initializes the virtual machine by configuring the host, installing necessary packages, creating a rootless user, configuring user SSH access, and installing the Podman initialization script
# Usage: sudo curl --location --output '/usr/local/bin/vm-init' 'https://raw.githubusercontent.com/marcobarrios-fi/podman-vm/main/podman-vm-init.sh' && sudo chmod +x /usr/local/bin/vm-init && sudo vm-init <configuration file path>

# Enable strict error handling (the script will stop immediately if a variable is not set or a command fails)
set -eu;

podman_vm_init() {

  echo "Initializing virtual machine...";

  # Operating system
  OPERATING_SYSTEM=$(. /etc/os-release && echo "$ID");

  # Verify that the operating system is supported
  if test "$OPERATING_SYSTEM" != "alpine" && test "$OPERATING_SYSTEM" != "ubuntu"; then
    echo "$(tput bold)$(tput setaf 1)Error: Unsupported operating system.$(tput sgr0)" && exit 1;
  fi

  # Verify that a configuration file was passed as an argument to the script
  if test ! -n "$@"; then
    echo "$(tput bold)$(tput setaf 1)Error: The required configuration file argument is missing.$(tput sgr0)" && exit 1;
  fi

  # Configuration file
  CONFIG_FILE="$1";
 
  # Verify that the configuration file exists
  if test ! -f "$CONFIG_FILE"; then
    echo "$(tput bold)$(tput setaf 1)Error: The provided configuration file does not exist.$(tput sgr0)" && exit 1;
  fi

  # Source configuration file
  . "$CONFIG_FILE";

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

  # Verify that the host data directory is specified
  if test ! -n "$HOST_DATA_DIR"; then
    echo "$(tput bold)$(tput setaf 1)Error: Host data directory is not specified.$(tput sgr0)" && exit 1;
  fi

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

  # Verify that the GitHub repository is specified
  if test ! -n "$GITHUB_REPO"; then
    echo "$(tput bold)$(tput setaf 1)Error: GitHub repository is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that the GitHub repository access token is specified
  if test ! -n "$GITHUB_REPO_TOKEN"; then
    echo "$(tput bold)$(tput setaf 1)Error: GitHub repository access token is not specified.$(tput sgr0)" && exit 1;
  fi

  # Pods, containers, and secrets are optional

  ### Hostname Configuration

  # Set hostname
  echo "Setting hostname to $HOST_NAME...";
  hostname "$HOST_NAME";
  echo "$HOST_NAME" > /etc/hostname;
  
  # Set host domain name
  echo "Setting host domain name to $HOST_DOMAIN_NAME...";
  echo "127.0.1.1 $HOST_DOMAIN_NAME $HOST_NAME" >> '/etc/hosts';

  ### Host Data Directory Configuration

  # Create host data directory if it does not exist
  if test ! -d "$HOST_DATA_DIR"; then
    echo "Creating host data directory...";
    mkdir -p "$HOST_DATA_DIR";
  fi

  # Verify that the host data directory exists
  if test ! -d "$HOST_DATA_DIR"; then
    echo "$(tput bold)$(tput setaf 1)Error: Host data directory does not exist.$(tput sgr0)" && exit 1;
  fi

  # Temporary scripts directory

  # Create temporary scripts directory
  echo "Creating temporary scripts directory...";
  TEMP_SCRIPTS_DIR=$(mktemp --directory);

  # Verify that the temporary scripts directory was successfully created
  if test ! -d "$TEMP_SCRIPTS_DIR"; then
    echo "$(tput bold)$(tput setaf 1)Error: Could not create temporary scripts directory.$(tput sgr0)" && exit 1;
  fi

  ### Packages

  echo "Installing packages...";

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

  ### User Initialization

  # User initialization script
  USER_INIT_SCRIPT="$TEMP_SCRIPTS_DIR/podman-vm-user-init.sh";

  # Download user initialization script
  echo "Downloading user initialization script...";
  curl --fail --location --silent --output "$USER_INIT_SCRIPT" 'https://raw.githubusercontent.com/marcobarrios-fi/podman-vm/main/podman-vm-user-init.sh';

  # Verify that the user initialization script was successfully downloaded
  if test ! -f "$USER_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: Could not downlaod user initialization script.$(tput sgr0)" && exit 1;
  fi

  # Execute user initialization script (passes the username, user ID, and user pubic SSH key as environment variables to the script)
  USER_NAME="$USER_NAME" USER_ID="$USER_ID" USER_KEY="$USER_KEY" sh "$USER_INIT_SCRIPT";

  # Delete user initialization script
  echo "Deleting user initialization script...";
  rm "$USER_INIT_SCRIPT";

  ### Rootless Podman Initialization

  # Rootless initialization script
  ROOTLESS_INIT_SCRIPT="$TEMP_SCRIPTS_DIR/podman-vm-rootless-init.sh";

  # Download rootless initialization script
  echo "Downloading rootless initialization script...";
  curl --fail --location --silent --output "$ROOTLESS_INIT_SCRIPT" 'https://raw.githubusercontent.com/marcobarrios-fi/podman-vm/main/podman-vm-rootless-init.sh';

  # Verify that the rootless initialization was successfully downloaded
  if test ! -f "$ROOTLESS_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: Could not download rootless initialization script.$(tput sgr0)" && exit 1;
  fi

  # Execute rootless initialization script (passes the username as environment variables to the script)
  USER_NAME="$USER_NAME" sh "$ROOTLESS_INIT_SCRIPT";

  # Delete rootless initialization script
  echo "Deleting rootless initialization script...";
  rm "$ROOTLESS_INIT_SCRIPT";

  echo "$(tput bold)$(tput setaf 2)Virtual machine initialization completed.$(tput sgr0)";

  ### Pods and Containers Initialization

  # Podman initialization script
  PODMAN_INIT_SCRIPT="$TEMP_SCRIPTS_DIR/podman-init.sh";

  # Download Podman initialization script
  echo "Downloading Podman initialization script...";
  curl --fail --location --silent --output "$PODMAN_INIT_SCRIPT" 'https://raw.githubusercontent.com/marcobarrios-fi/podman-vm/main/podman-init.sh';

  # Verify that the Podman initialization script was successfully downloaded
  if test ! -f "$PODMAN_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: Could not download Podman initialization script.$(tput sgr0)" && exit 1;
  fi

  # Execute Podman initialization script (passes domain, host data directory, username, GitHub repository, GitHub repository access token, pods, containers, and secrets as environment variables to the script)
  DOMAIN="$DOMAIN" HOST_DATA_DIR="$HOST_DATA_DIR" USER_NAME="$USER_NAME" GITHUB_REPO="$GITHUB_REPO" GITHUB_REPO_TOKEN="$GITHUB_REPO_TOKEN" PODS="$PODS" CONTAINERS="$CONTAINERS" SECRETS="$SECRETS" sh "$PODMAN_INIT_SCRIPT";

  # Switch to the user and execute the Podman initialization script
  echo "Switching to user $USER_NAME and executing Podman initialization script...";
  
  # su - "$USER_NAME" -c 'podman-init';

}

podman_vm_init "$@";
#!/bin/sh

# Podman Virtual Machine Initialization Shell Script
# Copyright ©️ 2025-2026 Marco Barrios. All rights reserved.
# Initializes the virtual machine by configuring the host, installing necessary packages, creating a rootless user, configuring user SSH access, and installing the Podman initialization script
# Usage: sudo curl --location --output '/usr/local/bin/vm-init' 'https://raw.githubusercontent.com/marcobarrios-fi/podman-vm/main/podman-vm-init.sh' && sudo chmod +x /usr/local/bin/vm-init && sudo vm-init <configuration file URL> <configuration file access token>

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

  # Verify that the configuration file URL is specified
  if test "$#" -lt 1; then
    echo "$(tput bold)$(tput setaf 1)Error: Configuration file URL is not specified.$(tput sgr0)";
    echo "Usage: $(tput bold)sudo vm-init <configuration file URL> <configuration file access token>$(tput sgr0)" && exit 1;
  fi

  # Verify that the configuration file access token is specified
  if test "$#" -lt 2; then
    echo "$(tput bold)$(tput setaf 1)Error: Configuration file access token is not specified.$(tput sgr0)";
    echo "Usage: $(tput bold)sudo vm-init <configuration file URL> <configuration file access token>$(tput sgr0)" && exit 1;
  fi

  # Configuration file URL
  CONFIG_FILE_URL="$1";

  # Configuration file access token
  CONFIG_FILE_TOKEN="$2";

  # Configuration file
  CONFIG_FILE=$(mktemp);

  # Download configuration file
  echo "Downloading configuration file...";
  curl --fail --location --silent --header "Authorization: Bearer $CONFIG_FILE_TOKEN" --output "$CONFIG_FILE" "$CONFIG_FILE_URL";  
 
  # Verify that the configuration file was successfully downloaded
  if test ! -f "$CONFIG_FILE"; then
    echo "$(tput bold)$(tput setaf 1)Error: Configuration file could not be downloaded.$(tput sgr0)" && exit 1;
  fi

  # Source configuration file
  . "$CONFIG_FILE";

  # Delete configuration file
  echo "Deleting configuration file...";
  rm "$CONFIG_FILE";

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

  ### Hostname

  # Set hostname
  echo "Setting hostname to $HOST_NAME...";
  hostname "$HOST_NAME";
  echo "$HOST_NAME" > /etc/hostname;
  
  # Set host domain name
  echo "Setting host domain name to $HOST_DOMAIN_NAME...";
  echo "127.0.1.1 $HOST_DOMAIN_NAME $HOST_NAME" >> '/etc/hosts';

  ### Host Data Directory

  # Create host data directory if it does not exist
  if test ! -d "$HOST_DATA_DIR"; then
    echo "Creating host data directory...";
    mkdir -p "$HOST_DATA_DIR";
  fi

  # Verify that the host data directory exists
  if test ! -d "$HOST_DATA_DIR"; then
    echo "$(tput bold)$(tput setaf 1)Error: Host data directory does not exist.$(tput sgr0)" && exit 1;
  fi

  ### Temporary Scripts Directory

  # Create temporary scripts directory
  echo "Creating temporary scripts directory...";
  TEMP_SCRIPTS_DIR=$(mktemp --directory);

  # Verify that the temporary scripts directory was successfully created
  if test ! -d "$TEMP_SCRIPTS_DIR"; then
    echo "$(tput bold)$(tput setaf 1)Error: Temporary scripts directory could not be created.$(tput sgr0)" && exit 1;
  fi

  # Display temporary scripts directory
  echo "Temporary scripts directory:"
  echo "$(tput bold)$(tput setaf 4)$TEMP_SCRIPTS_DIR$(tput sgr0)";

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
    echo "$(tput bold)$(tput setaf 1)Error: User initialization script could not be downloaded.$(tput sgr0)" && exit 1;
  fi

  # Execute user initialization script (passes the username, user ID, and user pubic SSH key as environment variables to the script)
  env USER_NAME="$USER_NAME" \
    env USER_ID="$USER_ID" \
    env USER_KEY="$USER_KEY" \
    sh "$USER_INIT_SCRIPT";

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
    echo "$(tput bold)$(tput setaf 1)Error: Rootless initialization script could not be downloaded.$(tput sgr0)" && exit 1;
  fi

  # Execute rootless initialization script (passes the username as environment variables to the script)
  env USER_NAME="$USER_NAME" \
    sh "$ROOTLESS_INIT_SCRIPT";

  # Delete rootless initialization script
  echo "Deleting rootless initialization script...";
  rm "$ROOTLESS_INIT_SCRIPT";
  
  ### Socket

  # Socket initialization script
  SOCKET_INIT_SCRIPT="$TEMP_SCRIPTS_DIR/podman-vm-socket-init.sh";

  # Download socket initialization script
  echo "Downloading socket initialization script...";
  curl --fail --location --silent --output "$SOCKET_INIT_SCRIPT" 'https://raw.githubusercontent.com/marcobarrios-fi/podman-vm/main/podman-vm-socket-init.sh';

  # Verify that the socket initialization script was successfully downloaded
  if test ! -f "$SOCKET_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: Socket initialization script could not be downloaded.$(tput sgr0)" && exit 1;
  fi

  # Execute socket initialization script as the Podman user (passes the user name as an environment variable to the script)
  env USER_NAME="$USER_NAME" \
    env USER_ID="$USER_ID" \
    sh "$SOCKET_INIT_SCRIPT";

  # Delete socket initialization script
  echo "Deleting socket initialization script...";
  rm "$SOCKET_INIT_SCRIPT";

  ### Clear

  # Remove temporary scripts directory
  echo "Removing temporary scripts directory...";
  # rm --recursive --force "$TEMP_SCRIPTS_DIR";
  rm -rf "$TEMP_SCRIPTS_DIR";

  ### Podman Initialization

  # Podman initialization script
  PODMAN_INIT_SCRIPT='/usr/local/bin/podman-init';

  # Download Podman initialization script
  echo "Downloading Podman initialization script...";
  curl --fail --location --silent --output "$PODMAN_INIT_SCRIPT" 'https://raw.githubusercontent.com/marcobarrios-fi/podman-vm/main/podman-init.sh';

  # Verify that the Podman initialization script was successfully downloaded
  if test ! -f "$PODMAN_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: Podman initialization script could not be downloaded.$(tput sgr0)" && exit 1;
  fi

  # Make Podman initialization script executable
  chmod +x "$PODMAN_INIT_SCRIPT";

  # Execute Podman initialization script as the Podman user (passes domain, host data directory, username, GitHub repository, GitHub repository access token, pods, containers, secrets, and temporary scripts directory as environment variables to the script)
  sudo --user "$USER_NAME" \
    env DOMAIN="$DOMAIN" \
    env HOST_DATA_DIR="$HOST_DATA_DIR" \
    env USER_NAME="$USER_NAME" \
    env GITHUB_REPO="$GITHUB_REPO" \
    env GITHUB_REPO_TOKEN="$GITHUB_REPO_TOKEN" \
    env PODS="$PODS" \
    env CONTAINERS="$CONTAINERS" \
    env SECRETS="$SECRETS" \
    env TEMP_SCRIPTS_DIR="$TEMP_SCRIPTS_DIR" \
    sh "$PODMAN_INIT_SCRIPT"

  # Delete Podman initialization script
  # echo "Deleting Podman initialization script...";
  # rm "$PODMAN_INIT_SCRIPT";

}

podman_vm_init "$@";
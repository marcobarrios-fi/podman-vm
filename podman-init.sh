#!/bin/sh

# Podman Initialization Shell Script
# Copyright ©️ 2025-2026 Marco Barrios. All rights reserved.
# Usage: chmod +x podman-init.sh && sh podman-init.sh;

# Enable strict error handling (the script will stop immediately if a variable is not set or a command fails)
set -eu;

podman_init() {

  echo "Initializing Podman...";

  # Verify configuration

  # Verify that the domain is specified
  if test ! -n "$DOMAIN"; then
    echo "$(tput bold)$(tput setaf 1)Error: Domain is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that the host data directory is specified
  if test ! -n "$HOST_DATA_DIR"; then
    echo "$(tput bold)$(tput setaf 1)Error: Host data directory is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that the user name is specified
  if test ! -n "$USER_NAME"; then
    echo "$(tput bold)$(tput setaf 1)Error: User name is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that the GitHub repository is specified
  if test ! -n "$GITHUB_REPO"; then
    echo "$(tput bold)$(tput setaf 1)Error: GitHub repository is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that the GitHub repository access token is specified
  if test ! -n "$GITHUB_REPO_TOKEN"; then
    echo "$(tput bold)$(tput setaf 1)Error: GitHub repository access token is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that pods are specified
  if test ! -n "$PODS"; then
    echo "$(tput bold)$(tput setaf 1)Error: Pods are not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that containers are specified
  if test ! -n "$CONTAINERS"; then
    echo "$(tput bold)$(tput setaf 1)Error: Containers are not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that secrets are specified
  if test ! -n "$SECRETS"; then
    echo "$(tput bold)$(tput setaf 1)Error: Secrets are not specified.$(tput sgr0)" && exit 1;
  fi

  ### Temporary Configuration Directory

  # Create temporary configuration directory
  echo "Creating temporary configuration directory...";
  TEMP_CONFIG_DIR=$(mktemp --directory);

  # Verify that the temporary configuration directory exists
  if test ! -d "$TEMP_CONFIG_DIR"; then
    echo "$(tput bold)$(tput setaf 1)Error: Temporary configuration directory does not exist.$(tput sgr0)" && exit 1;
  fi

  # Display temporary configuration directory
  echo "Temporary configuration directory:"
  echo "$(tput bold)$(tput setaf 4)$TEMP_CONFIG_DIR$(tput sgr0)";

  # Download GitHub repository
  echo "Downloading configuration files from GitHub repository...";
  git clone "$GITHUB_REPO_TOKEN@$GITHUB_REPO" "$TEMP_CONFIG_DIR";

  echo "$(tput bold)$(tput setaf 2)Downloading configuration files completed.$(tput sgr0)";

  ### Socket

  # Socket initialization script
  SOCKET_INIT_SCRIPT="$HOST_DATA_DIR/scripts/podman-socket-init.sh";

  # Download socket initialization script
  echo "Downloading socket initialization script...";
  curl --fail --silent --output "$SOCKET_INIT_SCRIPT" 'https://raw.githubusercontent.com/marcobarrios-fi/podman-vm/main/podman-socket-init.sh';

  # Verify that the socket initialization script exists
  if test ! -f "$SOCKET_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: Socket initialization script does not exist.$(tput sgr0)" && exit 1;
  fi

  # Execute socket initialization script (passes the user name as an environment variable to the script)
  USER_NAME="$USER_NAME" sh "$SOCKET_INIT_SCRIPT";

  # Delete socket initialization script
  echo "Deleting socket initialization script...";
  rm "$SOCKET_INIT_SCRIPT";

  ### Secrets

  # Secrets initialization script
  SECRETS_INIT_SCRIPT="$HOST_DATA_DIR/scripts/podman-secrets-init.sh";

  # Download secrets initialization script
  echo "Downloading secrets initialization script...";
  curl --fail --silent --output "$SECRETS_INIT_SCRIPT" 'https://raw.githubusercontent.com/marcobarrios-fi/podman-vm/main/podman-secrets-init.sh';

  # Verify that the secrets initialization script exists
  if test ! -f "$SECRETS_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: Secrets initialization script does not exist.$(tput sgr0)" && exit 1;
  fi

  # Execute secrets initialization script (passes secrets as an environment variable to the script)
  SECRETS="$SECRETS" sh "$SECRETS_INIT_SCRIPT";

  # Delete secrets initialization script
  echo "Deleting secrets initialization script...";
  rm "$SECRETS_INIT_SCRIPT";

  ### Pods

  # Pods initialization script
  PODS_INIT_SCRIPT="$HOST_DATA_DIR/scripts/podman-pods-init.sh";

  # Download pods initialization script
  echo "Downloading pods initialization script...";
  curl --fail --silent --output "$PODS_INIT_SCRIPT" 'https://raw.githubusercontent.com/marcobarrios-fi/podman-vm/main/podman-pods-init.sh';

  # Verify that the pods initialization script exists
  if test ! -f "$PODS_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: Pods initialization script does not exist.$(tput sgr0)" && exit 1;
  fi

  # Execute pods initialization script
  # (passes the domain, host data directory, pods list, and temporary configuration directory as environment variables to the script)
  DOMAIN="$DOMAIN" HOST_DATA_DIR="$HOST_DATA_DIR" PODS="$PODS" TEMP_CONFIG_DIR="$TEMP_CONFIG_DIR" sh "$PODS_INIT_SCRIPT";

  ### Containers

  # Containers initialization script
  CONTAINERS_INIT_SCRIPT="$HOST_DATA_DIR/scripts/podman-containers-init.sh";

  # Download containers initialization script
  echo "Downloading containers initialization script...";
  curl --fail --silent --output "$CONTAINERS_INIT_SCRIPT" 'https://raw.githubusercontent.com/marcobarrios-fi/podman-vm/main/podman-containers-init.sh';

  # Verify that the containers initialization script exists
  if test ! -f "$CONTAINERS_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: Containers initialization script does not exist.$(tput sgr0)" && exit 1;
  fi

  # Execute containers initialization script (passes the domain, host data directory, containers list, temporary configuration directory, and pod name as environment variables to the script)
  DOMAIN="$DOMAIN" HOST_DATA_DIR="$HOST_DATA_DIR" CONTAINERS="$CONTAINERS" TEMP_CONFIG_DIR="$TEMP_CONFIG_DIR" POD="" sh "$CONTAINERS_INIT_SCRIPT";

  ### Clear

  # Remove temporary configuration directory
  echo "Removing temporary configuration directory...";
  # rm --recursive --force "$TEMP_CONFIG_DIR";
  rm -rf "$TEMP_CONFIG_DIR";

  # Remove unused Podman images
  echo 'Removing unused Podman images...';
  podman image prune --all --force;

  # List Podman images
  echo "Podman container images:";
  podman images;

  echo "$(tput bold)$(tput setaf 2)Podman initialization completed.$(tput sgr0)";

}

podman_init;
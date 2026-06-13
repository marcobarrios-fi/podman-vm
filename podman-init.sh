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

  # Pods, containers, and secrets are optional

  ### Temporary Scripts Directory
  # Note: the non-root user does not have access to the temporary scripts directory created by the root user

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

  # Scripts URL
  SCRITPS_URL='https://raw.githubusercontent.com/marcobarrios-fi/podman-vm/main';

  ### Socket

  # Socket initialization script
  SOCKET_INIT_SCRIPT='podman-socket-init.sh';

  # Temporary socket initialization script
  TEMP_SOCKET_INIT_SCRIPT="$TEMP_SCRIPTS_DIR/$SOCKET_INIT_SCRIPT";

  # Download socket initialization script
  echo "Downloading socket initialization script...";
  curl --fail --location --silent --output "$TEMP_SOCKET_INIT_SCRIPT" "$SCRITPS_URL/$SOCKET_INIT_SCRIPT";

  # Verify that the socket initialization script was successfully downloaded
  if test ! -f "$TEMP_SOCKET_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: Socket initialization script could not be downloaded.$(tput sgr0)" && exit 1;
  fi

  # Execute socket initialization script as the Podman user (passes the user name as an environment variable to the script)
  env USER_NAME="$USER_NAME" \
  sh "$TEMP_SOCKET_INIT_SCRIPT";

  # Delete socket initialization script
  echo "Deleting socket initialization script...";
  rm "$TEMP_SOCKET_INIT_SCRIPT";

  ### Temporary Configuration Directory

  # Create temporary configuration directory
  echo "Creating temporary configuration directory...";
  TEMP_CONFIG_DIR=$(mktemp --directory);

  # Verify that the temporary configuration was successfully created
  if test ! -d "$TEMP_CONFIG_DIR"; then
    echo "$(tput bold)$(tput setaf 1)Error: Temporary configuration directory could not be created.$(tput sgr0)" && exit 1;
  fi

  # Display temporary configuration directory
  echo "Temporary configuration directory:"
  echo "$(tput bold)$(tput setaf 4)$TEMP_CONFIG_DIR$(tput sgr0)";

  # Download GitHub repository
  echo "Downloading configuration files from GitHub repository...";
  git clone "https://x-access-token:$GITHUB_REPO_TOKEN@github.com/$GITHUB_REPO.git" "$TEMP_CONFIG_DIR";

  echo "$(tput bold)$(tput setaf 2)Downloading configuration files completed.$(tput sgr0)";

  ### Secrets

  # Secrets initialization script
  SECRETS_INIT_SCRIPT='podman-secrets-init.sh';

  # Temporary secrets initialization script
  TEMP_SECRETS_INIT_SCRIPT="$TEMP_SCRIPTS_DIR/$SECRETS_INIT_SCRIPT";

  # Download secrets initialization script
  echo "Downloading secrets initialization script...";
  curl --fail --location --silent --output "$TEMP_SECRETS_INIT_SCRIPT" "$SCRITPS_URL/$SECRETS_INIT_SCRIPT";

  # Verify that the secrets initialization script was successfully downloaded
  if test ! -f "$TEMP_SECRETS_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: Secrets initialization script could not be downloaded.$(tput sgr0)" && exit 1;
  fi

  # Execute secrets initialization script (passes secrets as an environment variable to the script)
  env SECRETS="$SECRETS" \
    sh "$TEMP_SECRETS_INIT_SCRIPT";

  # Delete secrets initialization script
  echo "Deleting secrets initialization script...";
  rm "$TEMP_SECRETS_INIT_SCRIPT";

  ### Pods

  # Pods initialization script
  PODS_INIT_SCRIPT='podman-pods-init.sh';

  # Temporary pods initialization script
  TEMP_PODS_INIT_SCRIPT="$TEMP_SCRIPTS_DIR/$PODS_INIT_SCRIPT";

  # Download pods initialization script
  echo "Downloading pods initialization script...";
  curl --fail --silent --output "$TEMP_PODS_INIT_SCRIPT" "$SCRITPS_URL/$PODS_INIT_SCRIPT";

  # Verify that the pods initialization script was successfully downloaded
  if test ! -f "$TEMP_PODS_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: Pods initialization script could not be downloaded.$(tput sgr0)" && exit 1;
  fi

  # Execute pods initialization script (passes the domain, host data directory, pods list, and temporary configuration directory as environment variables to the script)
  env DOMAIN="$DOMAIN" \
  env HOST_DATA_DIR="$HOST_DATA_DIR" \
  env PODS="$PODS" \
  env TEMP_CONFIG_DIR="$TEMP_CONFIG_DIR" \
  sh "$TEMP_PODS_INIT_SCRIPT";

  # Delete pods initialization script
  echo "Deleting pods initialization script...";
  rm "$TEMP_PODS_INIT_SCRIPT";

  ### Containers

  # Containers initialization script
  CONTAINERS_INIT_SCRIPT='podman-containers-init.sh';

  # Temporary containers initialization script
  TEMP_CONTAINERS_INIT_SCRIPT="$TEMP_SCRIPTS_DIR/$CONTAINERS_INIT_SCRIPT";

  # Download containers initialization script
  echo "Downloading containers initialization script...";
  curl --fail --silent --output "$TEMP_CONTAINERS_INIT_SCRIPT" "$SCRITPS_URL/$CONTAINERS_INIT_SCRIPT";

  # Verify that the containers initialization script was successfully downloaded
  if test ! -f "$TEMP_CONTAINERS_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: Containers initialization script could not be downloaded.$(tput sgr0)" && exit 1;
  fi

  # Execute containers initialization script (passes the domain, host data directory, containers list, temporary configuration directory, and pod name as environment variables to the script)
  env DOMAIN="$DOMAIN" \
  env HOST_DATA_DIR="$HOST_DATA_DIR" \ 
  env CONTAINERS="$CONTAINERS" \
  env TEMP_CONFIG_DIR="$TEMP_CONFIG_DIR" \
  env POD="" \
  sh "$TEMP_CONTAINERS_INIT_SCRIPT";

  # Delete containers initialization script
  echo "Deleting containers initialization script...";
  rm "$TEMP_CONTAINERS_INIT_SCRIPT";

  ### Clear

  # Remove temporary scripts directory
  echo "Removing temporary scripts directory...";
  # rm --recursive --force "$TEMP_SCRIPTS_DIR";
  rm -rf "$TEMP_SCRIPTS_DIR";

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

 # Execute Podman initialization function (passes the domain, host data directory, username, GitHub repository, GitHub repository access token, pods, containers, and secrets as environment variables to the function)

env DOMAIN="$DOMAIN" \
env HOST_DATA_DIR="$HOST_DATA_DIR" \
env USER_NAME="$USER_NAME" \
env GITHUB_REPO_TOKEN="$GITHUB_REPO_TOKEN" \
env PODS="$PODS" \
env CONTAINERS="$CONTAINERS" \
env SECRETS="$SECRETS" \
podman_init;
#!/bin/sh

# Podman Pods Initialization Shell Script
# Copyright ©️ 2025-2026 Marco Barrios. All rights reserved.
# Initializes Podman pods and their containers
# Usage: chmod +x podman-pods-init.sh && sh podman-pods-init.sh

# Enable strict error handling (the script will stop immediately if a variable is not set or a command fails)
set -eu;

### Podman Pod Initialization Function
# Creates a Podman pod

podman_pod_init() {

  # Verify configuration

  # Verify that the domain is specified
  if test ! -n "$DOMAIN"; then
    echo "$(tput bold)$(tput setaf 1)Error: Domain is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that the host data directory is specified
  if test ! -n "$HOST_DATA_DIR"; then
    echo "$(tput bold)$(tput setaf 1)Error: Host data directory is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that the host data directory exists
  if test ! -d "$HOST_DATA_DIR"; then
    echo "$(tput bold)$(tput setaf 1)Error: Host data directory does not exist.$(tput sgr0)" && exit 1;
  fi

  # Verify that the temporary configuration directory is specified
  if test ! -n "$TEMP_CONFIG_DIR"; then
    echo "$(tput bold)$(tput setaf 1)Error: Temporary configuration directory is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that the configuration directory exists
  if test ! -d "$TEMP_CONFIG_DIR"; then
    echo "$(tput bold)$(tput setaf 1)Error: Temporary configuration directory does not exist.$(tput sgr0)" && exit 1;
  fi

  # Pod
  POD="$1";

  # Verify that pod is specified
  if test ! -n "$POD"; then
    echo "$(tput bold)$(tput setaf 1)Error: Pod is not specified.$(tput sgr0)" && exit 1;
  fi

  # Pod configuration file
  # (a configuration file containing space-separated list of pod containers)
  POD_CONFIG_FILE="$TEMP_CONFIG_DIR/podman/$POD-pod.conf";

  # Verify that the pod configuration file exists
  if test ! -f "$POD_CONFIG_FILE"; then
    echo "$(tput bold)$(tput setaf 1)Error: $POD pod configuration file does not exist.$(tput sgr0)" && exit 1;
  fi

  # Containers
  CONTAINERS="$(cat $POD_CONFIG_FILE)";

  # Prompt creating the pod
  printf "$(tput bold)Create $POD pod? (Yes/No) $(tput sgr0)" && read input;

  # Evaluate user input for creating the pod
  if test "$input" = "Yes" || test "$input" = "yes" || test "$input" = "Y" || test "$input" = "y"; then
    
    # Evaluate whether the pod exists
    if podman pod exists "$DOMAIN-$POD"; then
      
      echo "$POD pod already exists";
      
      # Prompt removing existing pod
      printf "$(tput bold)Remove existing $POD pod? (Yes/No) $(tput sgr0)" && read input;
      
      # Evaluate user input for removing existing pod
      if test "$input" = "Yes" || test "$input" = "yes" || test "$input" = "Y" || test "$input" = "y"; then
        
        # Remove existing pod
        echo "Removing $POD pod...";
        podman pod rm --force "$DOMAIN-$POD";
        
        # Create the pod
        echo "Creating $POD pod...";
        
        # Create pod with host networking
        podman pod create --name "$DOMAIN-$POD" --network='host';

      fi

    else
      
      # Create the pod
      echo "Creating $POD pod...";
      
      # Create pod with host networking
      podman pod create --name "$DOMAIN-$POD" --network='host';
    
    fi

  else

    echo "$(tput bold)$(tput setaf 3)Creating $POD pod canceled.$(tput sgr0)";
  
  fi

  # Containers initialization script
  CONTAINERS_INIT_SCRIPT="$HOST_DATA_DIR/scripts/podman-containers-init.sh";

  # Download containers initialization script
  echo "Downloading containers initialization script...";
  curl --fail --silent --output "$CONTAINERS_INIT_SCRIPT" 'https://raw.githubusercontent.com/marcobarrios-fi/podman-vm/main/podman-containers-init.sh';

  # Verify that the containers initialization script exists
  if test ! -f "$CONTAINERS_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: Containers initialization script does not exist.$(tput sgr0)" && exit 1;
  fi
  
  # Execute the container initialization script (passes the domain, host data directory, temporary configuration directory, containers list, and pod,as environment variables to the script)
  DOMAIN="$DOMAIN" HOST_DATA_DIR="$HOST_DATA_DIR" TEMP_CONFIG_DIR="$TEMP_CONFIG_DIR" CONTAINERS="$CONTAINERS" POD="$DOMAIN-$POD" sh "$CONTAINERS_INIT_SCRIPT"; 

  echo "$(tput bold)$(tput setaf 2)Creating $POD pod completed.$(tput sgr0)";

}

### Podman Pods Initialization Function
# Creates Podman pods

podman_pods_init() {

  # If pods are specified
  if test -n "$PODS"; then

    echo "Initializing Podman pods...";

    # Verify configuration

    # Verify that the domain is specified
    if test ! -n "$DOMAIN"; then
      echo "$(tput bold)$(tput setaf 1)Error: Domain is not specified.$(tput sgr0)" && exit 1;
    fi

    # Verify that the host data directory is specified
    if test ! -n "$HOST_DATA_DIR"; then
      echo "$(tput bold)$(tput setaf 1)Error: Host data directory is not specified.$(tput sgr0)" && exit 1;
    fi

    # Verify that the host data directory exists
    if test ! -d "$HOST_DATA_DIR"; then
      echo "$(tput bold)$(tput setaf 1)Error: Host data directory does not exist.$(tput sgr0)" && exit 1;
    fi

    # Verify that the temporary configuration directory is specified
    if test ! -n "$TEMP_CONFIG_DIR"; then
      echo "$(tput bold)$(tput setaf 1)Error: Temporary configuration directory is not specified.$(tput sgr0)" && exit 1;
    fi

    # Verify that the temporary configuration directory exists
    if test ! -d "$TEMP_CONFIG_DIR"; then
      echo "$(tput bold)$(tput setaf 1)Error: Temporary configuration directory does not exist.$(tput sgr0)" && exit 1;
    fi
    
    for POD in $PODS; do
      
      # Prompt initializing the pod
      printf "$(tput bold)Initialize $POD pod? (Yes/No) $(tput sgr0)" && read input;
      
      # Evaluate user input for initializing the pod
      if test "$input" = "YES" || test "$input" = "Yes" || test "$input" = "yes" || test "$input" = "Y" || test "$input" = "y"; then
        
        # Initialize pod (creates the pod)
        podman_pod_init "$POD";
      
      else 
        
        echo "$(tput bold)$(tput setaf 3)$POD pod initialization canceled.$(tput sgr0)";
      
      fi

    done

    echo "$(tput bold)$(tput setaf 2)Podman pods initialization completed.$(tput sgr0)";

  else
    
    echo "$(tput bold)$(tput setaf 3)Pods are not specified. Podman pods initialization skipped.$(tput sgr0)";
  
  fi   

}

podman_pods_init;
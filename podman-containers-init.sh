#!/bin/sh

# home.marcobarrios.no Podman Containers Initialization Shell Script
# Initializes Podman containers
# Usage: chmod +x podman-containers-init.sh && sh podman-containers-init.sh

# Enable strict error handling (the script will stop immediately if a variable is not set or a command fails)
set -eu;

### Podman Image Initialization Function
# Builds a Podman image

podman_image_init() {

  # Verify configuration

  # Verify that the domain is specified
  if test ! -n "$DOMAIN"; then
    echo "$(tput bold)$(tput setaf 1)Error: Domain is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that the temporary configuration directory is specified
  if test ! -n "$TEMP_CONFIG_DIR"; then
    echo "$(tput bold)$(tput setaf 1)Error: Temporary configuration directory is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that the temporary configuration directory exists
  if test ! -d "$TEMP_CONFIG_DIR"; then
    echo "$(tput bold)$(tput setaf 1)Error: Temporary configuration directory does not exist.$(tput sgr0)" && exit 1;
  fi

  # Container 
  CONTAINER="$1";

  # Verify that the container is specified
  if test ! -n "$CONTAINER"; then
    echo "$(tput bold)$(tput setaf 1)Error: Container is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that the container directory exists
  if test ! -d "$TEMP_CONFIG_DIR/$CONTAINER"; then
    echo "$(tput bold)$(tput setaf 1)Error: $CONTAINER container directory does not exist.$(tput sgr0)" && exit 1;
  fi

  # Verify that the container image file exists
  if test ! -f "$TEMP_CONFIG_DIR/$CONTAINER/$CONTAINER.image"; then
    echo "$(tput bold)$(tput setaf 1)Error: $CONTAINER container image file does not exist.$(tput sgr0)" && exit 1;
  fi

  # Image
  IMAGE="$DOMAIN/$CONTAINER";

  # Build container image
  echo "Building $CONTAINER container image...";
  podman build --no-cache --tag "$IMAGE" --build-arg-file "$TEMP_CONFIG_DIR/$CONTAINER/$CONTAINER-image.conf" --file "$TEMP_CONFIG_DIR/$CONTAINER/$CONTAINER.image";
  echo "$(tput bold)$(tput setaf 2)Building $CONTAINER container image completed.$(tput sgr0)";

}

### Podman Container Initialization Function
# Creates a Podman container

podman_container_init() {

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
  
  # Container name
  CONTAINER="$1";

  # Verify that the container is specified
  if test ! -n "$CONTAINER"; then
    echo "$(tput bold)$(tput setaf 1)Error: Container is not specified.$(tput sgr0)" && exit 1;
  fi

  # Verify that the container directory exists
  if test ! -d "$TEMP_CONFIG_DIR/$CONTAINER"; then
    echo "$(tput bold)$(tput setaf 1)Error: $CONTAINER container directory does not exist.$(tput sgr0)" && exit 1;
  fi
  
  # Container initialization script
  CONTAINER_INIT_SCRIPT="$TEMP_CONFIG_DIR/$CONTAINER/$CONTAINER-container-init.sh";
  
  # Verify that the container initialization script exists
  if test ! -f "$CONTAINER_INIT_SCRIPT"; then
    echo "$(tput bold)$(tput setaf 1)Error: $CONTAINER container initialization script does not exist.$(tput sgr0)" && exit 1;
  fi
  
  # Stop container if it exists
  if podman container exists "$DOMAIN-$CONTAINER"; then
    echo "Stopping $CONTAINER container...";
    podman stop "$DOMAIN-$CONTAINER";
  fi

  echo "Creating $CONTAINER container...";
  
  # Image
  IMAGE="$DOMAIN/$CONTAINER";

  # Execute the container initialization script (passes the host data directory, image, container, and pod name as environment variables to the script)
  HOST_DATA_DIR="$HOST_DATA_DIR" IMAGE="$IMAGE" CONTAINER="$DOMAIN-$CONTAINER" POD="$POD" sh "$CONTAINER_INIT_SCRIPT";
  
  echo "$(tput bold)$(tput setaf 2)Creating $CONTAINER container completed.$(tput sgr0)";

}

### Podman Containers Initialization Function
# Creates Podman containers

podman_containers_init() {
  
  # If containers are specified
  if test -n "$CONTAINERS"; then

    # Build container images and create containers
    echo "Initializing Podman containers...";

    # Verify that the temporary configuration directory is specified
    if test ! -n "$TEMP_CONFIG_DIR"; then
      echo "$(tput bold)$(tput setaf 1)Error: Temporary configuration directory is not specified.$(tput sgr0)" && exit 1;
    fi

    # Verify that the temporary configuration directory exists
    if test ! -d "$TEMP_CONFIG_DIR"; then
      echo "$(tput bold)$(tput setaf 1)Error: Temporary configuration directory does not exist.$(tput sgr0)" && exit 1;
    fi

    # Verify that the host data directory is specified
    if test ! -n "$HOST_DATA_DIR"; then
      echo "$(tput bold)$(tput setaf 1)Error: Host data directory is not specified.$(tput sgr0)" && exit 1;
    fi

    # Verify that the host data directory exists
    if test ! -d "$HOST_DATA_DIR"; then
      echo "$(tput bold)$(tput setaf 1)Error: Host data directory does not exist.$(tput sgr0)" && exit 1;
    fi

    # Verify that the domain is specified
    if test ! -n "$DOMAIN"; then
      echo "$(tput bold)$(tput setaf 1)Error: Domain is not specified.$(tput sgr0)" && exit 1;
    fi

    for CONTAINER in $CONTAINERS; do
      
      # Prompt initializing the container
      printf "$(tput bold)Initialize $CONTAINER container? (Yes/No) $(tput sgr0)" && read input;
      
      # Evaluate user input for initializing the container
      if test "$input" = "Yes" || test "$input" = "yes" || test "$input" = "Y" || test "$input" = "y"; then
        
        # Initalize (build) image
        podman_image_init "$CONTAINER";

        # Initialize (create) container
        podman_container_init "$CONTAINER";

      fi

    done

    echo "$(tput bold)$(tput setaf 2)Podman containers initialization completed.$(tput sgr0)";  

  else

    echo "$(tput bold)$(tput setaf 3)Containers are not specified. Podman containers initialization skipped.$(tput sgr0)";

  fi  

}

podman_containers_init;
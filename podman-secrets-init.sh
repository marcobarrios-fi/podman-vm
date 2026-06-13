#!/bin/sh

# Podman Secrets Initialization Shell Script
# Copyright ©️ 2025-2026 Marco Barrios. All rights reserved.
# Initializes Podman Cloudflare API token, DigitalOcean API token, and MQTT password secrets
# Usage: chmod +x podman-secrets-init.sh && sh podman-secrets-init.sh;

# Enable strict error handling (the script will stop immediately if a variable is not set or a command fails)
set -eu;

podman_secrets_init() {

  # Prompt initializing Podman secrets
  printf "$(tput bold)Initialize Podman secrets? (Yes/No) $(tput sgr0)" && read input;

  # Evaluate user input for initializing Podman secrets
  if test "$input" = "YES" || test "$input" = "Yes" || test "$input" = "yes" || test "$input" = "Y" || test "$input" = "y"; then

    echo "Initializing Podman secrets...";

    # If secrets are specified
    if test -n "$SECRETS"; then

      for SECRET in $SECRETS; do
        
        ### Cloudflare API Token

        if test "$SECRET" = 'cloudflare-api-token'; then

          # If Cloudflare API token secret does not exist
          if ! podman secret exists cloudflare-api-token; then
            # Prompt Cloudflare API token
            printf "$(tput bold)Enter Cloudflare API token: $(tput sgr0)" && read CLOUDFLARE_API_TOKEN;
            # Set Cloudflare API token environment variable
            export CLOUDFLARE_API_TOKEN;
            # Set Cloudflare API token secret
            podman secret create --env=true cloudflare-api-token 'CLOUDFLARE_API_TOKEN';
          fi

          # Display Cloudflare API token secret details
          echo 'Cloudflare API token secret:';
          podman secret inspect --pretty cloudflare-api-token && echo;

        ### DigitalOcean API Token

        elif test "$SECRET" = 'digitalocean-api-token'; then

          # If DigitalOcean API token secret does not exist
          if ! podman secret exists digitalocean-api-token; then
            # Prompt DigitalOcean API token
            printf "$(tput bold)Enter DigitalOcean API token: $(tput sgr0)" && read DIGITALOCEAN_API_TOKEN;
            # Set DigitalOcean API token environment variable
            export DIGITALOCEAN_API_TOKEN;
            # Set DigitalOcean API token secret
            podman secret create --env=true digitaocean-api-token 'DIGITALOCEAN_API_TOKEN';
          fi

          # Display DigitalOcean API token secret details
          echo 'DigitalOcean API token secret:';
          podman secret inspect --pretty digitalocean-api-token && echo;

        ### MQTT Password

        elif test "$SECRET" = 'mqtt-password'; then

          # If MQTT password secret does not exist
          if ! podman secret exists mqtt-password; then
            # Prompt MQTT password
            printf "$(tput bold)Enter MQTT password: $(tput sgr0)" && read MQTT_PASSWORD;
            # Set MQTT password environment variable
            export MQTT_PASSWORD;
            # Set MQTT password secret
            podman secret create --env=true mqtt-password 'MQTT_PASSWORD';
          fi

          # Display MQTT password secret details
          echo 'MQTT password secret:';
          podman secret inspect --pretty mqtt-password && echo;

        else

          echo "$(tput bold)$(tput setaf 1)Error: Unsupported secret $SECRET.$(tput sgr0)" && exit 1;
        
        fi

      done

      echo "$(tput bold)$(tput setaf 2)Podman secrets initialization completed.$(tput sgr0)";

    else 

      echo "$(tput bold)$(tput setaf 3)Warning: No secrets specified.$(tput sgr0)";

    fi

  else

    echo "$(tput bold)$(tput setaf 3)Podman secrets initialization canceled.$(tput sgr0)";

  fi

}

podman_secrets_init;
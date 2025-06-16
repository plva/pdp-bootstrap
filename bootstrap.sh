#!/bin/bash

# Initialize PDP configuration if it doesn't exist
PDP_CONFIG_FILE="config/pdp-config.json"
if [ ! -f "$PDP_CONFIG_FILE" ]; then
    # Get the current directory's parent (the PDP base directory)
    PDP_BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    
    # Create the config directory if it doesn't exist
    mkdir -p "$(dirname "$PDP_CONFIG_FILE")"
    
    # Create the config file with the current directory
    echo "{
    \"pdp_base_dir\": \"$PDP_BASE_DIR\"
}" > "$PDP_CONFIG_FILE"
    
    echo "Initialized PDP configuration at $PDP_CONFIG_FILE"
    echo "Base directory set to: $PDP_BASE_DIR"
fi

SCRIPTS_DIR='scripts'
CHECK_ZSH_SCRIPT='check_for_zsh.sh'
echo "Checking for zsh"

cd ${SCRIPTS_DIR}
./${CHECK_ZSH_SCRIPT}

exit_code=$?

# Check the exit code
if [ $exit_code -eq 0 ]; then
    echo "${CHECK_ZSH_SCRIPT} succeeded."
else
    echo "${CHECK_ZSH_SCRIPT} failed with exit code $exit_code."
    exit 1
fi

./setup.sh "$@"

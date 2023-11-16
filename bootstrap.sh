#!/bin/bash

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

./setup.sh

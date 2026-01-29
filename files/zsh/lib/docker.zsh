#!/usr/bin/env zsh
#
# Docker shared configuration
# Source this file in docker-related functions
#

# Run container as current user
__AX_DOCKER_ARGS_RUN_AS_ME=(
    "--user=$(id --user):$(id --group)"
)

# Remove container after exit
__AX_DOCKER_ARGS_ONE_TIME=(
    '--rm'
)

# Always pull latest image
__AX_DOCKER_ARGS_UP_TO_DATE=(
    '--pull=always'
)

# Interactive TTY session
__AX_DOCKER_ARGS_INTERACTIVE=(
    '--interactive'
    '--tty'
)

# Run in background
__AX_DOCKER_ARGS_BACKGROUND=(
    '--detach'
)

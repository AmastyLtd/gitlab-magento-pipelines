#!/bin/bash

# @command toolbox.sh
# @description Utility launcher.
# @author Eduard Muradov <eduard.muradov@amasty.com>

# @arg $1 tool name
# @arg $2 command name

# @env $SCRIPTS_DIR toolbox root directory (required)

set -e

# @arg $1 type
# @arg $1 message
custom_output() {
  case "$1" in
    error)
        printf "\033[1;31m%s\033[0m\n" "$2"
    ;;
    info)
        printf "\033[1m%s\033[0m\n" "$2"
    ;;
    success)
        printf "\033[1;32m%s\033[0m\n" "$2"
    ;;
    warning)
        printf "\033[1;33m%s\033[0m\n" "$2"
    ;;
    *)
        echo "Unknown output type: $1"
        exit 1
    ;;
  esac
}

# @arg $1 variable name
# @arg $2 variable value
check_required_var() {
  if [ -z "$2" ]; then
    custom_output error "Environment variable $1 is not set!"
    exit 1
  fi
}

# @arg $1 option name
# @arg $2 option value
check_option_value() {
    if [ -z "$2" ]; then
        custom_output error "Option $1 requires an argument!"

        return 1
    fi

    case "$2" in --*)
        custom_output error "Option $1 requires a valid argument!"

        return 1
    esac

    return 0
}

# @arg $1 command name
check_util() {
    if ! command -v "$1" > /dev/null; then
        custom_output error "$1 is not installed or not available thought PATH!"

        return 1
    fi

    return 0
}

# @arg $1 filename
load_file() {
    FILE="$1"
    shift

    # shellcheck source=/dev/null
    . "$SCRIPTS_DIR/$FILE"
}

# @arg $1 dirname
check_src_dir() {
    [ -d "$SCRIPTS_DIR/src/$1" ]
}

# @arg $1 filename
check_src_file() {
    [ -f "$SCRIPTS_DIR/src/$1" ]
}

get_toolbox_command() {
    echo "$0 $TOOL $OPERATION"
}

operation_help() {
    echo "Usage: $(get_toolbox_command) [options]"
    echo "Description:"
    echo -e "$OPERATION_DESCRIPTION"
    echo "Options:"
    echo -e "$OPERATION_OPTIONS"
}

if [ -z "$SCRIPTS_DIR" ] && [ ! -d "$SCRIPTS_DIR" ]; then
    custom_output error "SCRIPTS_DIR variable is not set or directory does not exist!"
    exit 1
fi

ASSETS_DIR="$(realpath "$SCRIPTS_DIR/assets/$1")"
export ASSETS_DIR

if [ -z "$1" ]; then
    custom_output error "Tool name is required!"
    echo "Usage: $0 <tool> <operation> [options]"

    exit 1
fi

TOOL="$1"

if ! check_src_dir "$TOOL"; then
    custom_output error "Tool $TOOL does not exist!"
    exit 1
fi

if [ -z "$2" ]; then
    custom_output error "Operation name is required!"
    echo "Usage: $0 <tool> <operation> [options]"


    exit 1
fi

OPERATION="$2"

if ! check_src_file "$TOOL/$OPERATION.sh"; then
    custom_output error "Operation $OPERATION does not exist!"
    exit 1
fi

shift 2

load_file "src/${TOOL}/${OPERATION}.sh" "$@"

#!/bin/bash
set -e
set -o pipefail

# @internal
# @author Eduard Muradov <eduard.muradov@amasty.com>

# @arg $1 python script filename
run_python_script() {
    local _script_path="$SCRIPTS_DIR/src/$1.py"
    local _python

    if [ ! -f "$_script_path" ]; then
        custom_output error "Script $1 does not exist!"
        exit 1
    fi

    shift

    if command -v python3 >/dev/null 2>&1; then
        _python=python3
    elif command -v python >/dev/null 2>&1; then
        _python=python
    else
        custom_output error "Python is not installed!"
        exit 1
    fi

    "$_python" "$_script_path" "$@"
}

# @arg $1 path to the directory with Magento 2 module
get_module_dir() {
    run_python_script get_module_name "$1"
}

# @arg $1 path to the directory with Magento 2 module
composer_installer() {
    run_python_script composer_installer
}

#!/bin/bash
set -e

# @internal
# @author Eduard Muradov <eduard.muradov@amasty.com>

generate_password() {
    local PASSWORD

    if [ -z "$1" ]; then
        custom_output error "Password length is required!"
        exit 1
    fi

    PASSWORD="$(openssl rand -base64 48 | cut -c1-"$1")"

    if [ -z "$PASSWORD" ]; then
        custom_output error "Password could not be generated!"
        exit 1
    fi

    echo "${PASSWORD}aA1"
}

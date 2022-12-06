#!/bin/sh
set -e

# @command toolbox.sh db dump
# @description Wrapper for mydumper/myloader utility.
# @author Eduard Muradov <eduard.muradov@amasty.com>


OPERATION_DESCRIPTION="\tThis tool is wrapper for mydumper/myloader utility.
\tTo create a dump, just run the script without any arguments.
\tIf you want to restore database dump, you should run this command with --restore option."

OPERATION_OPTIONS="\t--restore \t Restore database dump
\t--help \t\t Show this help"

# Check if database dump dir variable is set
if [ -z "$MYSQL_DATABASE" ]; then
    custom_output error "MYSQL_DATABASE variable is not set!"
    exit 1
fi

# Check if database dump dir variable is set
if [ -z "$DB_DUMP_DIR" ]; then
    custom_output error "DB_DUMP_DIR variable is not set!"
    exit 1
fi

[ -z "$MYSQL_HOST" ] && MYSQL_HOST="mysql"

if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
    MYSQL_USER="root"
    MYSQL_PASSWORD="$MYSQL_ROOT_PASSWORD"
fi

restore() {
    if [ ! -d "$DB_DUMP_DIR" ]; then
        custom_output error "Database dump directory does not exist."
        custom_output info "If you try to restart job, you should restart previous job first!"
        exit 1
    fi

    check_util myloader

    custom-output info "Restore database dump..."
    myloader \
        -h "${MYSQL_HOST}" \
        -u "${MYSQL_USER}" \
        -p "${MYSQL_PASSWORD}" \
        -B "${MYSQL_DATABASE}" \
        -d "${DB_DUMP_DIR}"
}

backup() {
    check_util mydumper

    custom_output info "Create database dump..."
    mydumper \
        -h "${MYSQL_HOST}" \
        -u "${MYSQL_USER}" \
        -p "${MYSQL_PASSWORD}" \
        -B "${MYSQL_DATABASE}" \
        -o "${DB_DUMP_DIR}"
}

# Check if we are restoring or creating a dump
case "$1" in
    --restore)
        restore
    ;;
    --help)
        operation_help
    ;;
    *)
        backup
    ;;
esac

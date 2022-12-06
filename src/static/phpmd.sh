#!/bin/bash
set -e

# @command toolbox.sh lint phpmd
# @description Wrapper for phpmd.
# @author Eduard Muradov <eduard.muradov@amasty.com>

export OPERATION_DESCRIPTION="\tRun PHP Mess Detector with Magento 2 ruleset."
export OPERATION_OPTIONS="\t--format\tFORMAT\t Format of the output (ansi|html|json|text|xml)
\t--help \t\t\t Show this help"

FORMAT="text"

case "$1" in
    --help | -h)
        operation_help
        exit 0
    ;;
    --format)
        check_option_value "$1" "$2" && FORMAT="$2" && shift 2 || exit 2
    ;;
    *)
        if [ -n "$1" ]; then
            custom_output warning "Unknown option: $1"
            exit 2
        fi
    ;;
esac

load_file src/magento.sh
load_file src/python.sh

BIN_PHPMD="${VENDOR_BIN_DIR}/phpmd"
TARGET_PATH="${MAGENTO_DIR}/app/code/$(get_module_dir "$CI_PROJECT_DIR")"
RULESET="$MAGENTO_DIR/dev/tests/static/testsuite/Magento/Test/Php/_files/phpmd/ruleset.xml"

custom_output info "Execute PHP Mess Detector"
"${BIN_PHPMD}" "${TARGET_PATH}" "${FORMAT}" "${RULESET}"

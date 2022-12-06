#!/bin/bash
set -e

# @command toolbox.sh phpunit unit
# @description Launcher for unit test for Magento 2 module.
# @author Eduard Muradov <eduard.muradov@amasty.com>

LOG_FILE_PATH="${CI_PROJECT_DIR}/unit-report.xml"

export OPERATION_DESCRIPTION="\tRun unit tests via phpunit for Magento 2 module."
export OPERATION_OPTIONS="\t--log-file\tFILE\t File to write the report to
\t--config\tFILE\t Path to phpunit.xml
\t--help \t\t\t Show this help"

while :; do
    case "$1" in
        --help | -h)
            operation_help
            exit 0
        ;;
        --log-file)
            check_option_value "$1" "$2" && LOG_FILE_PATH="$2" && shift 2 || exit 2
        ;;
        --config)
            check_option_value "$1" "$2" && PHPUNIT_CONFIG_PATH="$2" && shift 2 || exit 2
        ;;
        *)
            if [ -z "$1" ]; then
                break
            fi

            custom_output warning "Unknown option: $1"
            exit 2
        ;;
    esac
done

load_file src/phpunit.sh

custom-output info "Run unit tests..."
if [ -z "$PHPUNIT_CONFIG_PATH" ]; then
    PHPUNIT_CONFIG_PATH="${MAGENTO_DIR}/dev/tests/unit/phpunit.xml"
    cp "${ASSETS_DIR}/tests/unit/phpunit.xml" "${PHPUNIT_CONFIG_PATH}"
fi

"${VENDOR_BIN_DIR}/phpunit" \
    --configuration "${PHPUNIT_CONFIG_PATH}" \
    --log-junit "${LOG_FILE_PATH}" \
    "${MODULE_PATH}/Test/Unit"

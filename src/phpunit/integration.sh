#!/bin/bash
set -e

# @command toolbox.sh phpunit integration
# @description Launcher for unit test for Magento 2 module.
# @author Eduard Muradov <eduard.muradov@amasty.com>

LOG_FILE_PATH="${CI_PROJECT_DIR}/integration-report.xml"

export OPERATION_DESCRIPTION="\tRun integration tests via phpunit for Magento 2 module."
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

custom_output info "Prepare for running."
sed -i "s/\$dumpDb = true/\$dumpDb = false/g" "$MAGENTO_DIR/dev/tests/integration/framework/Magento/TestFramework/Application.php"
sed -i "s/if (\$this->isMacOS()) {/if (true) {/g" "$MAGENTO_DIR/dev/tests/integration/framework/Magento/TestFramework/Helper/Memory.php"

if [ -z "$PHPUNIT_CONFIG_PATH" ]; then
    PHPUNIT_CONFIG_PATH="${MAGENTO_DIR}/dev/tests/integration/phpunit.xml"
    cp "${ASSETS_DIR}/tests/integration/install-config-mysql.php" "${MAGENTO_DIR}/dev/tests/integration/etc/install-config-mysql.php"
    cp "${ASSETS_DIR}/tests/integration/phpunit.xml" "${PHPUNIT_CONFIG_PATH}"
fi

cd "$MAGENTO_DIR/dev/tests/integration"

custom-output info "Start integration tests."
"${VENDOR_BIN_DIR}/phpunit" \
    --debug \
    --configuration "${PHPUNIT_CONFIG_PATH}" \
    --log-junit "${LOG_FILE_PATH}" \
    "${MODULE_PATH}/Test/Integration"

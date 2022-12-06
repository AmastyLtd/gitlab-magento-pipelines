#!/bin/bash
set -e

# @command toolbox.sh phpunit api
# @description Launcher for API test for Magento 2 module.
# @author Eduard Muradov <eduard.muradov@amasty.com>

LOG_FILE_PATH="${CI_PROJECT_DIR}/api-report.xml"
TEST_TYPE=

export OPERATION_DESCRIPTION="\tRun API tests via phpunit for Magento 2 module."
export OPERATION_OPTIONS="\t--type \t\tTYPE\t Type of tests to run (rest, graphql)
\t--log-file\tFILE\t File to write the report to
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
        --type)
            case "$2" in
                rest)
                    TEST_TYPE="rest"
                ;;
                graphql)
                    TEST_TYPE="graphql"
                ;;
                *)
                    custom_output warning "Unknown API type: $2"
                    exit 2
                ;;
            esac
            shift 2
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

custom_output info "Prepare for running..."
if [ -z "$PHPUNIT_CONFIG_PATH" ]; then
    PHPUNIT_CONFIG_PATH="${MAGENTO_DIR}/dev/tests/api-functional/phpunit_${TEST_TYPE}.xml"
    cp "${ASSETS_DIR}/tests/api-integration/install-config-mysql.php" "${MAGENTO_DIR}/dev/tests/api-functional/config/install-config-mysql.php"
    cp "${ASSETS_DIR}/tests/api-integration/phpunit_${TEST_TYPE}.xml" "${PHPUNIT_CONFIG_PATH}"
fi

cd "$MAGENTO_DIR"
php -q -S 0.0.0.0:8082 -t "${MAGENTO_DIR}/pub/" "${MAGENTO_DIR}/phpserver/router.php" & PHP_SERVER_PID="$!"

set +e
cd "${MAGENTO_DIR}/dev/tests/integration"
custom-output info "Start API tests..."
"${VENDOR_BIN_DIR}/phpunit" \
    --debug \
    --configuration "${PHPUNIT_CONFIG_PATH}" \
    --log-junit "${LOG_FILE_PATH}" \
    "${MODULE_PATH}/Test/Api"
errorCode="$?"
set -e

kill "$PHP_SERVER_PID"

exit "$errorCode"

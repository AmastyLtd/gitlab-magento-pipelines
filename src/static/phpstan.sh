#!/bin/bash
set -e

# @command toolbox.sh lint phpstan
# @description Wrapper for phpstan.
# @author Eduard Muradov <eduard.muradov@amasty.com>

PHPSTAN_REPORT_FORMAT="table"
PHPSTAN_REPORT_FILE="/dev/stdout"

export OPERATION_DESCRIPTION="\tRun PHPStan with Magento 2 ruleset."
export OPERATION_OPTIONS="\t--report-format\tFORMAT\t Format of the output (table|raw|checkstyle|json|prettyJson|junit|gitlab|github) [default: ${PHPSTAN_REPORT_FORMAT}]
\t--report-file\tFILE\t File to write the report to [default: ${PHPSTAN_REPORT_FILE}]
\t--help \t\t\t Show this help"

while :; do
    case "$1" in
        --help | -h)
            operation_help
            exit 0
        ;;
        --report-format)
            check_option_value "$1" "$2" && PHPSTAN_REPORT_FORMAT="$2" && shift 2 || exit 2
        ;;
        --report-file)
            check_option_value "$1" "$2" && PHPSTAN_REPORT_FILE="$2" && shift 2 || exit 2
        ;;
        --gitlab)
            PHPSTAN_REPORT_FORMAT="gitlab"
            PHPSTAN_REPORT_FILE="$CI_PROJECT_DIR/phpstan-report.json"
            shift 1
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


load_file src/magento.sh
load_file src/python.sh

BIN_PHPSTAN="${VENDOR_BIN_DIR}/phpstan"
TARGET_PATH="${MAGENTO_DIR}/app/code/$(get_module_dir "$CI_PROJECT_DIR")"

[ -z "$PHPSTAN_NEON_PATH" ] && PHPSTAN_NEON_PATH="$MAGENTO_DIR/dev/tests/static/testsuite/Magento/Test/Php/_files/phpstan/phpstan.neon"

custom-output info "Running PHPStan analyze with ${PHPSTAN_SEVERITY:-0} level (memory limit: ${PHPSTAN_MEMORY_LIMIT:-2048M})"
"${BIN_PHPSTAN}" analyze \
    --level="${PHPSTAN_SEVERITY:-0}" \
    --memory-limit="${PHPSTAN_MEMLIMIT:-2048M}" \
    --configuration="$PHPSTAN_NEON_PATH" \
    --error-format="${PHPSTAN_REPORT_FORMAT}" "${TARGET_PATH}" > "${PHPSTAN_REPORT_FILE}"

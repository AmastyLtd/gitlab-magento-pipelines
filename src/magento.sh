#!/bin/bash
set -e

# @internal
# @author Eduard Muradov <eduard.muradov@amasty.com>

# Check if Magento dir variable is set and directory exists
if [ -z "$MAGENTO_DIR" ] && [ ! -d "$MAGENTO_DIR" ]; then
    custom_output error "MAGENTO_DIR variable is not set or directory does not exist!"
    exit 1
fi

if [ ! -f "$MAGENTO_DIR/bin/magento" ]; then
    custom_output error "Cannot find bin/magento in $MAGENTO_DIR!"
    exit 1
fi

if [ ! -x "$MAGENTO_DIR/bin/magento" ]; then
    if ! chmod +x "$MAGENTO_DIR/bin/magento"; then
        custom_output error "bin/magento is not executable and we cannot fix it from here!"
        exit 1
    fi
fi

MAGENTO_DIR="$(realpath "$MAGENTO_DIR")"

export VENDOR_BIN_DIR="${MAGENTO_DIR}/vendor/bin"

[ -z "$MAGE_STATIC_BUILD_TREADS" ] && MAGE_STATIC_BUILD_TREADS="$(nproc)"

check_mode() {
    case "$1" in
        production|developer|default)
            return 0
        ;;
        *)
            custom_output error "Unknown mode: $1"
            custom_output warning "Available modes: production, developer, default."

            return 1
        ;;
    esac
}

bin_magento() {
    "$MAGENTO_DIR/bin/magento" "$@"
}

bin_magento_std() {
    "$MAGENTO_DIR/bin/magento" "$@" 2>> "$STDERR_FILE" 1>> "$STDOUT_FILE"
}

magento_upgrade() {
    custom_output info "Running bin/magento setup:upgrade"
    bin_magento setup:upgrade
}

magento_dry_upgrade() {
    custom_output info "Running (dry) bin/magento setup:upgrade"
    bin_magento setup:upgrade --dry-run=1 --magento-init-params="MAGE_MODE=developer"
}

magento_set_deploy_mode() {
    custom_output info "Switching to $1 mode..."
    bin_magento deploy:mode:set "$1" --skip-compilation
}

magento_deploy() {
    custom_output info "Running bin/magento setup:di:compile"
    bin_magento setup:di:compile

    custom_output info "Deploying static content (threads: $MAGE_STATIC_BUILD_TREADS)"
    bin_magento setup:static-content:deploy -f -s standard -j "$MAGE_STATIC_BUILD_TREADS"
}

clean_generated() {
    custom_output info "Cleaning generated files..."
    rm -rf "${MAGENTO_DIR}/var/cache/*" \
        "${MAGENTO_DIR}/var/view_preprocessed/*" \
        "${MAGENTO_DIR}/generated/code/*" \
        "${MAGENTO_DIR}/generated/metadata/*" \
        "${MAGENTO_DIR}/pub/static/*" || return 0
}

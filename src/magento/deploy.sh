#!/bin/bash
set -e

# @command toolbox.sh magento deploy
# @description Wrapper for Magento 2 deploy process.
# @author Eduard Muradov <eduard.muradov@amasty.com>

export OPERATION_DESCRIPTION="\tWrapper for Magento 2 deploy process."
export OPERATION_OPTIONS="\t--production \t\t\t Shortcut for '--mage-mode production --force-cleanup'
\t--skip-dry-upgrade \t\t Skip dry run for setup:upgrade
\t--force-cleanup \t\t Force cleanup generated files
\t--mage-mode \t\tMODE\t Set Magento 2 mode (production|developer|default)
\t--static-build-threads \tTHREADS\t Set number of threads for static content deploy"

MAGE_MODE=
FORCE_CLEANUP=0
SKIP_DRY_UPGRADE=0

while :; do
    case "$1" in
        --production)
            MAGE_MODE="production"
            FORCE_CLEANUP=1
            shift 1
        ;;
        --mage-mode)
            check_option_value "$1" "$2" && check_mode "$2" && MAGE_MODE="$2" && shift 2 || exit 2
        ;;
        --static-build-threads)
            check_option_value "$1" "$2" && export MAGE_STATIC_BUILD_TREADS="$2" && shift 2 || exit 2
        ;;
        --force-cleanup)
            FORCE_CLEANUP=1
            shift 1
        ;;
        --skip-dry-upgrade)
            SKIP_DRY_UPGRADE=1
            shift 1
        ;;
        --help | -h)
            operation_help
            exit 0
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
cd "$MAGENTO_DIR"

if [ "$FORCE_CLEANUP" -eq 1 ]; then
    clean_generated
fi

if [ "$SKIP_DRY_UPGRADE" -eq 0 ]; then
    magento_dry_upgrade
fi

magento_upgrade

if [ -n "$MAGE_MODE" ]; then
    magento_set_deploy_mode "$MAGE_MODE"
fi

magento_deploy

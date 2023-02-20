#!/bin/bash
set -e

# @command toolbox.sh magento mftf
# @description Wrapper for running MFTF test groups.
# @author Eduard Muradov <eduard.muradov@amasty.com>

export OPERATION_DESCRIPTION="\tThis tool prepare Magento 2 and run MFTF test group."
export OPERATION_OPTIONS="\t--help \t\t Show this help"

case "$1" in
    --help | -h)
        operation_help
        exit 0
    ;;
    *)
        if [ -n "$1" ]; then
            custom_output warning "Unknown option: $1"
            exit 2
        fi
    ;;
esac

load_file src/magento.sh

# Check if envsubst is available
check_util envsubst

BIN_MFTF="${VENDOR_BIN_DIR}/mftf"
AMASTY_SMOKE_MODULE_ENABLED="${AMASTY_SMOKE_MODULE_ENABLED:-0}"
MAGENTO_BASE_URL="http://$(hostname -i | awk '{print $1}')/"

export STDERR_FILE="/dev/stdin"
export STDOUT_FILE="/dev/null"

echo "Magento base_url: $MAGENTO_BASE_URL"

cd "$MAGENTO_DIR"

echo "Start log at $(date)" > $STDERR_FILE

custom_output info "Configure 2FA for admin user..."
bin_magento_std config:set twofactorauth/general/force_providers google
bin_magento_std config:set twofactorauth/google/otp_window 60
bin_magento_std security:tfa:google:set-secret admin MFRGGZDF
# ------------------------------------------------------------

custom_output info "Configure Magento Settings..."
bin_magento_std config:set cms/wysiwyg/enabled disabled
bin_magento_std config:set admin/security/admin_account_sharing 1
bin_magento_std config:set admin/security/use_form_key 0
bin_magento_std config:set web/seo/use_rewrites 1
bin_magento_std config:set web/unsecure/base_url "$MAGENTO_BASE_URL"
# ------------------------------------------------------------

bin_magento cache:clean config full_page

custom_output info "Configure .env & .credentials files..."
{
  echo "MAGENTO_BASE_URL=$MAGENTO_BASE_URL"
  echo "MAGENTO_BACKEND_NAME=admin"
  echo "MAGENTO_ADMIN_USERNAME=admin"
  echo "MAGENTO_ADMIN_PASSWORD=${MAGE_ADMIN_PASSWORD:-a111111}"
  echo "SELENIUM_CLOSE_ALL_SESSIONS=true"
  echo "SELENIUM_HOST=${SELENIUM_HOST:-selenium}"
  echo "SELENIUM_PORT=4444"
  echo "SELENIUM_PROTOCOL=http"
  echo "SELENIUM_PATH=/wd/hub"
  echo "BROWSER=chrome"
  echo "WAIT_TIMEOUT=120"
} > "$MAGENTO_DIR/dev/tests/acceptance/.env"

{
  echo 'magento/tfa/OTP_SHARED_SECRET=MFRGGZDF'
  echo "magento/MAGENTO_ADMIN_PASSWORD=${MAGE_ADMIN_PASSWORD:-a111111}"
} > "$MAGENTO_DIR/dev/tests/acceptance/.credentials"
# ------------------------------------------------------------

custom_output info "Start NGINX and PHP-FPM..."
export MAGENTO_DIR PHP_MEMORY_LIMIT="4G"
sudo --preserve-env=ASSETS_DIR,MAGENTO_DIR sh -c 'envsubst '"'"'${MAGENTO_DIR}'"'"' < "${ASSETS_DIR}/templates/nginx.conf.template" > /etc/nginx/http.d/default.conf'
sudo --preserve-env=ASSETS_DIR,PHP_MEMORY_LIMIT sh -c 'envsubst < "${ASSETS_DIR}/templates/fpm-pool.conf.template" > /usr/local/etc/php-fpm.d/www.conf'

sudo php-fpm -D -R > /dev/null 2>&1
sudo nginx

if [ "${AMASTY_SMOKE_MODULE_ENABLED}" -eq 1 ]; then
  custom_output info "Run amasty:smoke:generate..."
  bin_magento amasty:smoke:generate
fi

custom_output info "Generate MFTF tests..."
"${BIN_MFTF}" build:project

set +e
custom_output info "Run MFTF tests..."
"${BIN_MFTF}" run:group "$MFTF_TEST_GROUP_NAME" && touch "$CI_PROJECT_DIR/.success_exit_code"

# Force exit with 0 code to prevent job failure
exit 0

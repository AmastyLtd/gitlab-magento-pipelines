#!/bin/bash
set -e

# @command toolbox.sh magento install
# @description Perform Magento 2 setup:install only.
# @author Eduard Muradov <eduard.muradov@amasty.com>

: <<EOF
@section Operation required variables
@env MAGENTO_DIR Magento 2 root directory (required)
EOF

: <<EOF
@section Database connection variables
@env MYSQL_HOST      Host (optional, default: mysql)
@env MYSQL_DATABASE  Name (required)
@env MYSQL_USER      User (required)
@env MYSQL_PASSWORD  Password (required)
EOF

: <<EOF
@section Magento 2 setup:install Elasticsearch variables
@env ES_HOST      Host (required, if Magento 2.4+)
@env ES_PORT      Port (optional, default: 9200)
@env ES_AUTH      Auth required (optional, default: false)
@env ES_USER      User (optional)
@env ES_PASSWORD  Password (optional)
EOF

:<<EOF
@section Magento 2 setup:install admin user variables
@env MAGE_ADMIN_FIRSTNAME First name (optional, default: Example)
@env MAGE_ADMIN_LASTNAME  Last name (optional, default: Admin)
@env MAGE_ADMIN_EMAIL     E-mail (optional, default: admin@example.com)
@env MAGE_ADMIN_USERNAME  Username (optional, default: admin)
@env MAGE_ADMIN_PASSWORD  Password (optional, default: <random>)
EOF

: <<EOF
@section Other Magento 2 setup:install variables
@env MAGE_BASE_URL Base URL (optional, default: http://localhost/)
@env MAGE_BACKEND_FRONTNAME Backend frontname (optional, default: admin)
@env MAGE_LANGUAGE Language (optional, default: en_US)
@env MAGE_CURRENCY Currency (optional, default: USD)
@env MAGE_TIMEZONE Timezone (optional, default: America/Chicago)
EOF

export OPERATION_DESCRIPTION="\tThis tool install Magento 2 via setup:install."
export OPERATION_OPTIONS="\t--create-admin \t Create admin user
\t--help \t\t Show this help"

CREATE_ADMIN_USER=0

while :; do
    case "$1" in
        --help | -h)
            operation_help
            exit 0
        ;;
        --create-admin)
            CREATE_ADMIN_USER=1

            shift
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
load_file src/password.sh

check_required_var MYSQL_USER "$MYSQL_USER"
check_required_var MYSQL_PASSWORD "$MYSQL_PASSWORD"
check_required_var MYSQL_DATABASE "$MYSQL_DATABASE"

install_args=(
    --db-host="${MYSQL_HOST:-mysql}" \
    --db-name="$MYSQL_DATABASE" \
    --db-user="$MYSQL_USER" \
    --db-password="$MYSQL_PASSWORD" \
)

if [ -z "$ES_HOST" ]; then
    custom_output warning "Magento 2 will be istalled without Elasticsearch!"
else
    install_args+=(
        --search-engine=elasticsearch7 \
        --elasticsearch-enable-auth="${ES_AUTH:-false}" \
        --elasticsearch-host="$ES_HOST" \
        --elasticsearch-port="${ES_PORT:-9200}"
    )

    if [ "$ES_AUTH" == "true" ]; then
        check_required_var ES_USER "$ES_USER"
        check_required_var ES_PASSWORD "$ES_PASSWORD"

        install_args+=(
            --elasticsearch-username="$ES_USER" \
            --elasticsearch-password="$ES_PASSWORD"
        )
    fi
fi

[[ -z "$MAGE_ADMIN_PASSWORD" ]] && MAGE_ADMIN_PASSWORD="$(generate_password 10)"

if [ "$CREATE_ADMIN_USER" -eq 1 ]; then
    install_args+=(
        --admin-firstname="${MAGE_ADMIN_FIRSTNAME:-Example}" \
        --admin-lastname="${MAGE_ADMIN_LASTNAME:-Admin}" \
        --admin-email="${MAGE_ADMIN_EMAIL:-admin@example.com}" \
        --admin-user="${MAGE_ADMIN_USERNAME:-admin}" \
        --admin-password="$MAGE_ADMIN_PASSWORD"
    )
fi

install_args+=(
    --base-url="${MAGE_BASE_URL:-http://localhost/}" \
    --backend-frontname="${MAGE_BACKEND_FRONTNAME:-admin}" \
    --language="${MAGE_LANGUAGE:-en_US}" \
    --currency="${MAGE_CURRENCY:-USD}" \
    --timezone="${MAGE_TIMEZONE:-America/Chicago}" \
    --use-rewrites=1 \
)

custom_output info "Magento 2 will be installed with the following arguments: "
echo "${install_args[*]}"
bin_magento setup:install "${install_args[@]}"
custom_output success "Magento 2 has been installed."

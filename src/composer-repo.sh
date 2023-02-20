#!/bin/bash
set -e

composer_get_name() {
    # shellcheck disable=SC2001
    echo "$1" | sed -e 's/[^[:alnum:]]//g'
}

composer_add_domains() {
    if [ -n "$COMPOSER_GITLAB_DOMAINS" ]; then
        # shellcheck disable=SC2068
        composer config --global gitlab-domains ${COMPOSER_GITLAB_DOMAINS[@]}
    fi
}

composer_add_repositories() {
    if [ -n "$COMPOSER_REPOSITORIES" ]; then
        # shellcheck disable=SC2068
        for package in ${COMPOSER_REPOSITORIES[@]}; do
            name=$(composer_get_name "${package}")
            composer config repositories."${name}" composer "${package}"
        done
    fi

    if [ -n "$COMPOSER_REPOSITORIES_VCS" ]; then
        # shellcheck disable=SC2068
        for package in ${COMPOSER_REPOSITORIES_VCS[@]}; do
            name=$(composer_get_name "${package}")
            composer config repositories."${name}" vcs "${package}"
        done
    fi
}

composer_add_packages() {
    if [ -n "$COMPOSER_PACKAGES" ]; then
        # shellcheck disable=SC2068
        composer require ${COMPOSER_PACKAGES[@]}
    fi
}

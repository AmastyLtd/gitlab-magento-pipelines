#!/bin/bash
set -e

# @command toolbox.sh modules add
# @description Add current module and download it dependencies.
# @author Eduard Muradov <eduard.muradov@amasty.com>

: <<EOF
@section GitLab CI/CD variables
@env CI_PROJECT_DIR Current project directory (required unless you are using --skip-ci-module option)
EOF

: <<EOF
@section Optional variables
@env MODULE_DEPS        List of required modules. Format: <namespace_with_group>.git. E.g. 'magento2/base.git' (optional)
@env SMOKE_MODULE_PATH  Path to module for smoke test (optional)
@env COMPOSER_AUTH      JSON-encoded auth data for composer (optional) @see https://getcomposer.org/doc/03-cli.md#composer-auth
EOF

export OPERATION_DESCRIPTION="\t This tool installs current module and it dependencies."
export OPERATION_OPTIONS="\t--skip-ci-module \t\t Skip installation module from CI_PROJECT_DIR directory
\t--skip-ci-module-deps \t\t Skip dependencies installation from MODULE_DEPS variable
\t--skip-composer-deps \t\t Skip composer dependencies installation
\t--with-smoke-module \t\t Install module from SMOKE_MODULE_PATH variable
\t--branch \t\tBRANCH \t Alias for --ci-module-branch <branch> and --ci-module-deps-branch <branch>
\t--ci-module-branch \tBRANCH\t Branch of module to install from CI_PROJECT_DIR directory (default: <current branch>)
\t--ci-module-deps-branch BRANCH\t Branch of dependencies to install from MODULE_DEPS variable (default: <current branch>)
\t--help \t\t\t\t Show this help"

# Flags
SKIP_CI_MODULE=0
SKIP_CI_MODULE_DEPENDENCIES=0

CI_MODULE_BRANCH=
CI_MODULE_DEPENDENCIES_BRANCH=

INSTALL_COMPOSER_DEPENDENCIES=1
INSTALL_MODULE_SMOKE_TEST=0

while :; do
    case "$1" in
        --help | -h)
            operation_help
            exit 0
        ;;
        --skip-ci-module)
            SKIP_CI_MODULE=1

            shift
        ;;
        --skip-ci-module-deps)
            SKIP_CI_MODULE_DEPENDENCIES=1

            shift
        ;;
        --branch)
            check_option_value "$1" "$2" || exit 2
            CI_MODULE_BRANCH="$2"
            CI_MODULE_DEPENDENCIES_BRANCH="$2"

            shift 2
        ;;
        --ci-module-branch)
            check_option_value "$1" "$2" && CI_MODULE_BRANCH="$2" && shift 2 || exit 2
        ;;
        --ci-module-deps-branch)
            check_option_value "$1" "$2" && CI_MODULE_DEPENDENCIES_BRANCH="$2" && shift 2 || exit 2
        ;;
        --skip-composer-deps)
            INSTALL_COMPOSER_DEPENDENCIES=0

            shift
        ;;
        --with-smoke-module)
            INSTALL_MODULE_SMOKE_TEST=1
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
load_file src/python.sh
load_file src/git.sh

install_module() {
    local _target_dir _module_path _module_branch _remote _tmp_path

    _module_path="$1"
    _module_branch="$2"
    _remote="$(get_git_remote_url "$_module_path")"
    _tmp_path="$(mktemp -d)"

    if [ -z "$_module_branch" ]; then
        _module_branch="$(get_clone_branch "$_remote")"
    fi

    custom-output info "Getting $_module_path. Origin: $_remote. Branch: $_module_branch"
    git_clone "$_remote" "$_tmp_path" "$_module_branch"

    _target_dir="${CODE_DIR}/$(get_module_dir "$_tmp_path")"

    mkdir -p "$(dirname "${_target_dir}")"
    mv "$_tmp_path" "${_target_dir}"
}

install_composer_deps() {
    cd "$MAGENTO_DIR"

    if [ -z "$COMPOSER_AUTH" ]; then
        custom_output warning "COMPOSER_AUTH variable is empty. Composer auth data will not be used."
        (composer config --unset repositories.\* && custom_output warning "All repositories were removed from Magento2 composer.json") || true
    fi

    composer_installer

    return 0
}

# Check if CI_PROJECT_DIR is set and it is a directory
if [ -z "$CI_PROJECT_DIR" ] || [ ! -d "$CI_PROJECT_DIR" ]; then
    custom_output error "CI_PROJECT_DIR is not set or it is not a directory"
    exit 1
fi

CODE_DIR="$MAGENTO_DIR/app/code/";

if [ ! -d "$CODE_DIR" ]; then
  mkdir -p "$CODE_DIR"
fi

cd "$CODE_DIR"

if [ "$SKIP_CI_MODULE_DEPENDENCIES" -eq 0 ]; then
    if [ -z "$MODULE_DEPS" ]; then
        custom_output warning "MODULE_DEPS variable is empty. Dependencies will not be installed."
    else
        for MODULE in $MODULE_DEPS; do
            install_module "$MODULE" "$CI_MODULE_DEPENDENCIES_BRANCH"
        done
    fi
fi

if [ "$SKIP_CI_MODULE" -eq 0 ]; then
    if [ -z "$CI_MODULE_BRANCH" ]; then
        custom-output info "Add main module with current branch"
        _real_dir="$(get_module_dir "$CI_PROJECT_DIR")"

        mkdir -p "$(dirname "$_real_dir")"
        cp -rf "$CI_PROJECT_DIR" "$(get_module_dir "$CI_PROJECT_DIR")"
    else
        custom-output info "Add main module with $CI_MODULE_BRANCH branch"
        install_module "$CI_REPOSITORY_URL" "$CI_MODULE_BRANCH"
    fi
fi

if [ "$INSTALL_COMPOSER_DEPENDENCIES" -eq 1 ]; then
    custom_output info "Install composer dependencies..."
    install_composer_deps
fi

if [ "$INSTALL_MODULE_SMOKE_TEST" -eq 1 ]; then
    if [ -z "$SMOKE_MODULE_PATH" ]; then
        custom_output error "SMOKE_MODULE_PATH is not set"
        exit 1
    fi

    custom_output info "Add smoke test module"
    install_module "$SMOKE_MODULE_PATH" "$PRODUCTION_READY_BRANCH"
fi

#!/bin/bash
set -e

if [ "${CI_DEBUG_TRACE}" == "true" ]; then
    set -x
fi

args=(
    -s
    --standard="${PHPCS_CODE_STANDARD:-Amasty}"
    --severity="${PHPCS_SEVERITY:-1}"
    --report-width="${PHPCS_REPORT_WIDTH:-150}"
    --report-code
    --colors
)

get_modified_files() {
    local REPO_MAIN_BRANCH_NAME="${REPO_MAIN_BRANCH_NAME:-master}"
    git config --global --add safe.directory "${CI_PROJECT_DIR}" >/dev/null

    if git rev-parse --is-shallow-repository | grep true >/dev/null 2>&1; then
        git -C "${CI_PROJECT_DIR}" fetch --unshallow >/dev/null
    fi

    git -C "${CI_PROJECT_DIR}" fetch origin "${REPO_MAIN_BRANCH_NAME}:${REPO_MAIN_BRANCH_NAME}" --update-head-ok >/dev/null
    git -C "${CI_PROJECT_DIR}" diff-tree --diff-filter=dr --name-only -r "${REPO_MAIN_BRANCH_NAME}" "${CI_COMMIT_SHA}" -- "$@"
}

if [ -n "${PHPCS_EXCLUDED_RULES}" ]; then
    args+=(--exclude="${PHPCS_EXCLUDED_RULES}")
fi

if [ -n "${PHPCS_IGNORE_ANNOTATIONS}" ]; then
    args+=(--ignore-annotations)
fi

if [ -n "${PHPCS_FILE_EXTENSIONS}" ]; then
    args+=(
        --extensions="${PHPCS_FILE_EXTENSIONS}"
    )
fi

if [ -n "${PHPCS_BASE_PATH}" ]; then
    args+=(
        --basepath="${PHPCS_BASE_PATH}"
    )
fi

if [ -n "${CI_PROJECT_DIR}" ]; then
    args+=(
        --report-junit="${CI_PROJECT_DIR}/junit.xml"
        --report-diff="${CI_PROJECT_DIR}/phpcbf.patch"
    )

    if [ "$PHPCS_ALL_FILES" == 1 ]; then
        if [ -n "$*" ]; then
            args+=("$@")
        else
            args+=("${CI_PROJECT_DIR}")
        fi
    else
        for dir in "$@"; do
            if [ ! -d "${CI_PROJECT_DIR}/${dir}" ]; then
                custom-output.sh error "Directory ${dir} does not exist inside ${CI_PROJECT_DIR}!"
                exit 1
            fi
        done

        readarray -t _modified < <(get_modified_files "$@")

        if [ -z "${_modified[*]}" ]; then
            custom-output.sh info "No modified files found"
            exit 0
        fi

        _modified=( "${_modified[@]/#/${CI_PROJECT_DIR}/}" )

        args+=("${_modified[@]}")
    fi
else
    args+=("$@")
fi

custom-output.sh info "Running phpcs with arguments:"
echo "${args[@]}"
"$PHPCS_PATH/vendor/bin/phpcs" "${args[@]}"

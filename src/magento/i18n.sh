#!/bin/bash
set -e

# @command toolbox.sh magento i18n
# @description Generate i18n files and push it back to repository.
# @author Eduard Muradov <eduard.muradov@amasty.com>

export OPERATION_DESCRIPTION="\tGenerate i18n files and push them to the current repository."
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
load_file src/git.sh

if [ "${CI_COMMIT_REF_NAME}" = "${PRODUCTION_READY_BRANCH}" ]; then
    custom_output info "Whoops! Master ${CI_COMMIT_REF_NAME} is here. Exit."

    exit 0
fi

WORK_DIR="$(mktemp -d)"

# Clone full repository
git clone "$(get_git_remote_url "$CI_PROJECT_PATH.git")" -b "$CI_COMMIT_REF_NAME" "${WORK_DIR}"

if [ ! -d "${WORK_DIR}/i18n/" ]; then
  mkdir -p "${WORK_DIR}/i18n/"
fi

if ! bin_magento i18n:collect-phrases --output="${WORK_DIR}/i18n/en_US.csv" "$CI_PROJECT_DIR"; then
  custom_output info "No phrases found or error has been occured. Skipping..."
  exit 0
fi;

cd "$WORK_DIR"

git add "$WORK_DIR/i18n/en_US.csv"

# Commit without [skip ci] tag for correctly displaying status of piplines in merge request.
if git commit -m "Update i18n."; then
  custom_output success "i18n successfully updated."
  git push
  custom_output success "Push successfull."

  custom_output warning "Cancel current pipline. New piplines should be runned."
  curl --request POST --header "PRIVATE-TOKEN: $CONF_CTOKEN" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/pipelines/${CI_PIPELINE_ID}/cancel" > /dev/null 2>&1
else
  custom_output info "No phrases found. Skipping..."
fi

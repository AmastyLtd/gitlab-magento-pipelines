#!/bin/bash
set -e

_work_dir="${1:-$PHPCS_PATH/tmp}";

if [ -d "$_work_dir" ]; then
    rm -rf "$_work_dir"
fi

mkdir -p "$_work_dir"

custom-output.sh info "Clone dependent modules";

# Check that base module included, if not - add it
if [[ ! "${MODULE_DEPS}" =~ magento2\/base\.git ]]; then
  MODULE_DEPS+=("magento2/base.git")
fi

for _repo in "${MODULE_DEPS[@]}"; do
  _remote="https://${CONF_CUSERNAME}:${CONF_CTOKEN}@git.amasty.com/${_repo}"
  _branch="${REPO_MAIN_BRANCH_NAME:-master}";

  if [ "$_repo" = "$CI_PROJECT_PATH.git" ]; then
    custom-output.sh info "Request to install ${_repo} has been skipped. Current module \"${CI_PROJECT_PATH}\" is the same."
    continue
  fi
  
  # Check if same branch exists in dependent module repository
  if [ -n "${CI_COMMIT_BRANCH}" ] && git ls-remote --exit-code --heads "${_remote}" "${CI_COMMIT_BRANCH}"; then
    _branch="${CI_COMMIT_BRANCH}";
  elif [ -n "${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}" ] && git ls-remote --exit-code --heads "${_remote}" "${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}"; then
    _branch="${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}";
  elif [ -n "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}" ] && git ls-remote --exit-code --heads "${_remote}" "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}"; then
    _branch="${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}";
  fi

  _branch="$(git ls-remote --heads "${_remote}" "${_branch}" | cut -d/ -f3-)"

  custom-output.sh info "Getting ${_repo}. Origin: ${_remote}. Branch: ${_branch}"
  git clone --depth 1 -b "${_branch}" "${_remote}" "${_work_dir}/${_repo//\//_}"
  git -C "${_work_dir}/${_repo//\//_}" remote rm origin
done

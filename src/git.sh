#!/bin/bash
set -e

# @internal
# @author Eduard Muradov <eduard.muradov@amasty.com>

: <<EOF
@section Operation required variables
@env PRODUCTION_READY_BRANCH    Production ready branch name (optional, default: master)
@env CONF_CUSERNAME             Username to clone repositories (required)
@env CONF_CTOKEN                Token to clone repositories (required)
EOF

[ -z "$PRODUCTION_READY_BRANCH" ] && PRODUCTION_READY_BRANCH="master"

check_required_var CONF_CUSERNAME "$CONF_CUSERNAME"
check_required_var CONF_CTOKEN "$CONF_CTOKEN"

# @arg $1 Remote repository URL (with auth data if needed)
# @arg $2 Directory to clone into
# @arg $3 Branch to checkout
git_clone() {
    check_required_var URL "$1" && _remote_url="$1"
    check_required_var DIR "$2" && _target_dir="$2"

    [ -n "$3" ] && _branch="$3"

    if [ ! -d "$(dirname "$_target_dir")" ]; then
        mkdir -p "$(dirname "$_target_dir")"
    fi

    if [ -n "$_branch" ]; then
        git clone --branch "$_branch" "$_remote_url" "$_target_dir"
    else
        git clone "$_remote_url" "$_target_dir"
    fi
}

# @arg $1 remote repository URL (with auth data if needed)
get_clone_branch() {
    check_required_var _remote_url "$1" && _remote_url="$1"
    _result_branch="$PRODUCTION_READY_BRANCH"

    if [ -n "$CI_COMMIT_BRANCH" ] && git ls-remote --exit-code --heads "$_remote_url" "$CI_COMMIT_BRANCH"; then
      _result_branch="$CI_COMMIT_BRANCH"
    elif [ -n "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME" ] && git ls-remote --exit-code --heads "$_remote_url" "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"; then
      _result_branch="$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"
    elif [ -n "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME" ] && git ls-remote --exit-code --heads "$_remote_url" "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME"; then
      _result_branch="$CI_MERGE_REQUEST_TARGET_BRANCH_NAME"
    fi

    echo "$_result_branch"
}

# @arg $1 remote repository path with .git suffix
get_git_remote_url() {
    check_required_var _repo_path "$1" && _repo_path="$1"

    echo "https://${CONF_CUSERNAME}:${CONF_CTOKEN}@${CI_SERVER_HOST}:${CI_SERVER_PORT}/${_repo_path}"
}

#!/bin/sh
set -e

git config --global user.email "$CONF_CUSERNAME@amasty.com"
git config --global user.name "Gitlab CI"

exec "$@"

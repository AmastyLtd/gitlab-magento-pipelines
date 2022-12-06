#!/bin/bash
set -e

# @internal
# @author Eduard Muradov <eduard.muradov@amasty.com>

load_file src/magento.sh
load_file src/python.sh

export MODULE_PATH
MODULE_PATH="${MAGENTO_DIR}/app/code/$(get_module_dir "$CI_PROJECT_DIR")"

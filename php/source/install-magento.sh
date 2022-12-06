#!/bin/sh
set -e
export COMPOSER_HOME="/kaniko/.composer";

composer create-project --no-install --repository=https://repo.magento.com/ "magento/project-$MAGENTO_EDITION-edition=$MAGENTO_VERSION" "$MAGENTO_DIR"
cd "$MAGENTO_DIR"

if [ -n "$1" ]; then
  composer require --no-update "$@"
fi;

composer config --no-plugins allow-plugins.laminas/laminas-dependency-plugin true
composer config --no-plugins allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
composer config --no-plugins 'allow-plugins.magento/*' true

composer install
composer clear-cache

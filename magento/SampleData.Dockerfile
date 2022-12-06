ARG BASE_IMAGE=''
FROM $BASE_IMAGE

RUN cd "${MAGENTO_DIR}" && mkdir -p var/composer_home/ && \
    ln -s $HOME/.composer/auth.json var/composer_home/ && \
    bin/magento sampledata:deploy --no-update && \
    composer remove --no-update magento/sample-data-media && \
    composer update && composer clear-cache && rm -rf "${MAGENTO_DIR}/var/composer_home"

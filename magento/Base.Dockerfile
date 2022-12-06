ARG BASE_IMAGE=''
FROM $BASE_IMAGE

ARG COMPOSER_REQUIRES

ARG MAGENTO_VERSION
ENV MAGENTO_VERSION ${MAGENTO_VERSION}

ARG MAGENTO_EDITION="community"
ENV MAGENTO_EDITION "${MAGENTO_EDITION}"

ENV MAGENTO_DIR "$HOME/magento"
ENV PHPSTAN_NEON_PATH "$MAGENTO_DIR/dev/tests/static/testsuite/Magento/Test/Php/_files/phpstan/phpstan.neon"

LABEL maintainer="Eduard Muradov <eduard.muradov@amasty.com>"
LABEL gitlab.pipline.magento_version="$MAGENTO_VERSION"
LABEL gitlab.pipline.magento_edition="$MAGENTO_EDITION"

RUN /usr/local/bin/install-magento.sh $COMPOSER_REQUIRES

RUN rm -f $HOME/.composer/auth.json

WORKDIR $MAGENTO_DIR

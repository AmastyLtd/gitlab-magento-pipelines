FROM alpine:3.17

ENV PHPCS_PATH /app
ENV COMPOSER_MEMORY_LIMIT=-1

ARG CLONE_URL
ARG VERSION

RUN apk add --no-cache \
    git=~2.38 curl=~7.87 bash=~5.2 \
    php81=~8.1 php81-phar=~8.1 php81-mbstring=~8.1 php81-openssl=~8.1 php81-tokenizer=~8.1 \
    php81-xmlwriter=~8.1 php81-simplexml=~8.1 php81-dom=~8.1 php81-ctype=~8.1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --2.2 --filename=composer
RUN adduser worker -D -s /bin/bash && \
    mkdir -p "${PHPCS_PATH}" && chown worker:worker "${PHPCS_PATH}"

COPY bin/ /usr/local/bin
USER worker

RUN git clone --quiet "${CLONE_URL}" "${PHPCS_PATH}" && rm -rf "$PHPCS_PATH/.git"

WORKDIR /app

RUN composer require --quiet --no-update "magento/magento-coding-standard=${VERSION}" && \
    composer install --quiet

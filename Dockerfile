FROM rockylinux:8

ARG ALLURE_VERSION=2.18.1
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0

RUN dnf -y install git curl java-1.8.0-openjdk-devel &&\
    curl -L -o /tmp/allure.rpm \
        https://github.com/allure-framework/allure2/releases/download/${ALLURE_VERSION}/allure_${ALLURE_VERSION}-1.noarch.rpm && \
    rpm -i /tmp/allure.rpm --nodeps && \
    rm -rf /tmp/allure.rpm && dnf clean all

RUN useradd --uid 1000 --shell /bin/sh --create-home worker

COPY ./source/ /usr/local/bin/
USER worker

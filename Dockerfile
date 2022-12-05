FROM python:3.10-alpine

ENV HOME /src
ENV PATH "$HOME:$PATH"

COPY src "${HOME}"

RUN apk add --no-cache git=~2.38.1 && \
    adduser worker -h "$HOME" -D && \
    pip install --no-cache-dir -r "${HOME}/requirements.txt"

USER worker
WORKDIR "${HOME}"

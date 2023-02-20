FROM python:3.10-alpine3.16

ENV HOME /app
ENV PATH "$HOME/bin:$PATH"

COPY . "${HOME}"

RUN apk add --no-cache git=~2.36 && \
    adduser worker -h "$HOME" -D && \
    pip install --no-cache-dir -r "${HOME}/requirements.txt"

USER worker
WORKDIR "${HOME}"

ENTRYPOINT ["/app/entrypoint.sh"]

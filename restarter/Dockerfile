FROM docker:cli

RUN apk add --no-cache coreutils tzdata

COPY ./restarter.sh /restarter.sh

ENTRYPOINT ["/restarter.sh"]
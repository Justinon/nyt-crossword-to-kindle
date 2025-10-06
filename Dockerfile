FROM alpine:latest

RUN apk update && \
    apk add --no-cache curl bash coreutils tzdata jq exiftool ghostscript mutt xmlstarlet python3 py3-pip libxml2-dev libxslt-dev gobject-introspection cairo-dev pango-dev gdk-pixbuf-dev fontconfig ttf-dejavu && \
    python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir weasyprint bs4 lxml && \
    deactivate && \
    mkdir -p /crosswords/tmp && \
    chmod -R 777 /crosswords/tmp

# Set user and group to ensure permissions
RUN addgroup -S crossword && adduser -S crossword -G crossword
USER crossword

ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /crosswords

COPY ./Muttrc /etc/Muttrc
COPY ./download-crossword.sh download-crossword.sh
COPY ./download-cbc-news.sh download-cbc-news.sh
COPY ./process_html.py process_html.py
COPY ./main.sh main.sh

ENTRYPOINT ["./main.sh"]
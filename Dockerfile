FROM alpine:latest

RUN apk update && \
    apk add --no-cache curl bash coreutils tzdata jq exiftool ghostscript mutt && \
    mkdir /crosswords

WORKDIR /crosswords

COPY ./Muttrc /etc/Muttrc
COPY ./download-crossword.sh download-crossword.sh

ENTRYPOINT ["./download-crossword.sh", "--linux"]
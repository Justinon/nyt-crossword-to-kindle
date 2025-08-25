#!/usr/bin/env bash

if [ -f ${HOME}/.bashrc ]; then
    source ~/.bashrc
elif [ -f ${HOME}/.zprofile ]; then
    source ~/.zprofile
fi

SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"

pushd ${SCRIPT_PATH}

docker-compose up

popd
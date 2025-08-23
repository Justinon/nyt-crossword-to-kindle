#!/usr/bin/env bash

source ~/.zprofile

SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"

pushd ${SCRIPT_PATH}

docker-compose up -d

popd
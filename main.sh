#!/usr/bin/env bash

set -eo pipefail

SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"

get_human_readable_time_from_seconds() {
  local seconds="${1}"
  local hours=$((diff / 3600))
  local minutes=$(((diff % 3600) / 60))
  local seconds=$((diff % 60))
  echo "${hours} hours ${minutes} minutes and ${seconds} seconds"
}

get_human_readable_time_from_epoch_seconds() {
  local epoch_seconds="${1}"
  echo $(date -d "@${epoch_seconds}" +"%b %-d %Y, %H:%M")
}

get_wait_time() {
    local target=${1}
    local now=$(date +%s)
    echo $(( target - now ))
}

wait_until_send_time() {
  local restart_time="${1}"
  local now=$(date +%s)
  local target=$(date -d "${restart_time}" +%s)
  
  echo "The current time is: $(get_human_readable_time_from_epoch_seconds ${now})"
  
  # If target time has already passed today, move to tomorrow
  if [ "${target}" -le "${now}" ]; then
      target=$(date -d "tomorrow ${restart_time}" +%s)
  fi
  echo "Next restart will be: $(get_human_readable_time_from_epoch_seconds ${target})"

  # Wait until it's time to send again
  local diff=$(get_wait_time ${target})
  while [ "${diff}" -ge 0 ]; do
    echo "Waiting another $(get_human_readable_time_from_seconds ${diff}) to send..."
    sleep 60;
    diff=$(get_wait_time ${target})
  done
}

#### BEGIN MAIN EXECUTION

# Initial downloads
${SCRIPT_PATH}/download-crossword.sh ${CROSSWORD_COMMAND_LINE_ARGUMENTS}
${SCRIPT_PATH}/download-cbc-news.sh

# Daily crossword and news sending
while true; do
  RESTART_TIME="${CROSSWORD_DAILY_SEND_TIME:-08:00}"
  echo "Will send your crossword and news every day at: ${RESTART_TIME} ${TZ} time"

  wait_until_send_time "${RESTART_TIME}"

  # Source .env to detect any changes to command-line arguments
  source ${SCRIPT_PATH}/.env
  ${SCRIPT_PATH}/download-crossword.sh ${CROSSWORD_COMMAND_LINE_ARGUMENTS}
  ${SCRIPT_PATH}/download-cbc-news.sh
done
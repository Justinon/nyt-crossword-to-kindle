#!/bin/sh

while true; do
  RESTART_TIME="${DAILY_CROSSWORD_SEND_TIME:-08:00}"
  echo "Detected restart time: ${RESTART_TIME}"

  # Current time
  now=$(date +%s)
  now_human_friendly=$(date -d "@${now}" +"%b %-d %Y, %H:%M")
  echo "The current time is: ${now_human_friendly}"

  # Candidate restart time today
  target=$(date -d "$RESTART_TIME" +%s)

  # If that time has already passed today, move to tomorrow
  if [ "$target" -le "$now" ]; then
      target=$(date -d "tomorrow $RESTART_TIME" +%s)
  fi
  target_human_friendly=$(date -d "@${target}" +"%b %-d %Y at %H:%M")
  echo "Next restart will be: ${target_human_friendly}"

  # Difference in seconds
  diff=$(( target - now ))
  diff_human_friendly=$(date -ud "@${diff}" +"%H hours %M minutes and %S seconds...")
  echo "See you in ${diff_human_friendly}..."

  sleep $diff;
  source /.env
  docker compose up $RESET_SERVICES -d --force-recreate
done
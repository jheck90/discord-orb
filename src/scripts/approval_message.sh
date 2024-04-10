#!/bin/bash

# Provide error if no webhook is set and error. Otherwise continue
if [ -z "${WEBHOOK}" ]; then
  echo "NO DISCORD WEBHOOK SET"
  echo "Please input your DISCORD_WEBHOOK value either in the settings for this project, or as a parameter for this orb."
  exit 1
else
  echo "Webhook: ${WEBHOOK}" # Debugging message
  
  #Create Members string
  if [ -n "${MENTIONS}" ]; then
    IFS="," read -ra DISCORD_MEMBERS <<< "${MENTIONS}"
    for i in "${DISCORD_MEMBERS[@]}"; do
      if echo "${i}" | grep -E "^(here|everyone)$" > /dev/null; then
        DISCORD_MENTIONS="${DISCORD_MENTIONS}@${i} "
      else
        DISCORD_MENTIONS="${DISCORD_MENTIONS}<@${i}> "
      fi
    done
  fi

  echo "Message: ${MESSAGE}" # Debugging message
  echo "Mentions: ${DISCORD_MENTIONS}" # Debugging message
  echo "Color: ${COLOR}" # Debugging message
  echo "Include Project Field: ${INCLUDE_PROJECT_FIELD}" # Debugging message
  echo "Include Job Number Field: ${INCLUDE_JOB_NUMBER_FIELD}" # Debugging message
  echo "URL: ${URL}" # Debugging message
  
  curl -X POST -H 'Content-type: application/json' \
  --data \
  "{
    \"content\": \"$(echo "${MESSAGE} ${DISCORD_MENTIONS}" | sed 's/"/\\"/g')\",
    \"embeds\": [{
      \"description\": \"$(echo "${MESSAGE} - ${URL}" | sed 's/"/\\"/g')\",
      \"color\": \"$(echo "${COLOR}" | sed 's/"/\\"/g')\",
      \"fields\": [
        $(if [[ "${INCLUDE_PROJECT_FIELD}" == "true" ]]; then
          echo "{
            \"name\": \"Project\",
            \"value\": \"$(echo "${CIRCLE_PROJECT_REPONAME}" | sed 's/"/\\"/g')\",
            \"inline\": true
          }$(if [[ "${INCLUDE_JOB_NUMBER_FIELD}" == "true" ]]; then echo ","; fi)"
        fi)
        $(if [[ "${INCLUDE_JOB_NUMBER_FIELD}" == "true" ]]; then
          echo "{
            \"name\": \"Job Number\",
            \"value\": \"$(echo "${CIRCLE_BUILD_NUM}" | sed 's/"/\\"/g')\",
            \"inline\": true
          }"
        fi)
      ]
    }]
  }" "${WEBHOOK}"
  echo "Awaiting approval notified."
fi

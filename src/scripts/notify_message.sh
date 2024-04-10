#!/bin/bash

# Provide error if no webhook is set and error. Otherwise continue
if [ -z "${WEBHOOK}" ]; then
  echo "NO DISCORD WEBHOOK SET"
  echo "Please input your DISCORD_WEBHOOK value either in the settings for this project, or as a parameter for this orb."
  exit 1
else
  echo "Webhook: ${WEBHOOK}" # Debugging message
  echo "Notifying Discord Channel" # Debugging message
  
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
  echo "Message: ${MESSAGE} ${DISCORD_MENTIONS}" # Debugging message
  
  curl -X POST -H 'Content-type: application/json' \
    --data \
      "{
        \"content\": \"$(echo "${MESSAGE} ${DISCORD_MENTIONS}" | sed 's/"/\\"/g')\",
        \"embeds\": [{
          \"author\": {
            \"name\": \"${AUTHOR_NAME}\",
            \"url\": \"${AUTHOR_LINK}\",
            \"icon_url\": \"${AUTHOR_ICON}\"
          },
          \"title\": \"${TITLE}\",
          \"url\": \"${TITLE_LINK}\",
          \"description\": \"${MESSAGE} ${CIRCLE_BUILD_URL}\",
          \"color\": \"${COLOR}\",
          \"fields\": [
            $(if [[ "${INCLUDE_PROJECT_FIELD}" == "true" ]]; then
              echo "{
                \"name\": \"Project\",
                \"value\": \"${CIRCLE_PROJECT_REPONAME}\",
                \"inline\": true
              }$(if [[ "${INCLUDE_JOB_NUMBER_FIELD}" == "true" ]]; then echo ","; fi)"
            fi)
            $(if [[ "${INCLUDE_JOB_NUMBER_FIELD}" == "true" ]]; then
              echo "{
                \"name\": \"Job Number\",
                \"value\": \"${CIRCLE_BUILD_NUM}\",
                \"inline\": true
              }"
            fi)
          ],
          \"timestamp\": \"${TS}\",
          \"footer\": {
            \"text\": \"${FOOTER}\"
          }
        }]
      }" "${WEBHOOK}"
fi

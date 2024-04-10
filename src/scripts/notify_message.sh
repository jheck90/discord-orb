#!/bin/bash

# Provide error if no webhook is set and error. Otherwise continue
if [ -z "${WEBHOOK}" ]; then
  echo "NO DISCORD WEBHOOK SET"
  echo "Please input your DISCORD_WEBHOOK value either in the settings for this project, or as a parameter for this orb."
  exit 1
else
  echo "Webhook: ${WEBHOOK}" # Debugging message
  echo "Notifying Discord Channel" # Debugging message
  
  # Create Members string
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
  
  # Prepare JSON data without using sed
  author=$(jq -n --arg name "${AUTHOR_NAME}" --arg url "${AUTHOR_LINK}" --arg icon "${AUTHOR_ICON}" '{$name, $url, $icon}')
  fields="["
  if [[ "${INCLUDE_PROJECT_FIELD}" == "true" ]]; then
    fields+="$(jq -n --arg project "${CIRCLE_PROJECT_REPONAME}" '{$name: "Project", $value: $project, $inline: true}')"
    if [[ "${INCLUDE_JOB_NUMBER_FIELD}" == "true" ]]; then
      fields+=","
    fi
  fi
  if [[ "${INCLUDE_JOB_NUMBER_FIELD}" == "true" ]]; then
    fields+="$(jq -n --arg jobNumber "${CIRCLE_BUILD_NUM}" '{$name: "Job Number", $value: $jobNumber, $inline: true}')"
  fi
  fields+="]"
  embed=$(jq -n --argjson author "$author" --arg title "${TITLE}" --arg url "${TITLE_LINK}" --arg message "${MESSAGE} ${CIRCLE_BUILD_URL}" --arg color "${COLOR}" --argjson fields "$fields" --arg ts "${TS}" --arg footer "${FOOTER}" '{$author, $title, $url, $description: $message, $color, $fields, $timestamp: $ts, $footer}')

  # Send the request
  curl -X POST -H 'Content-type: application/json' \
    --data \
    "{
      \"content\": \"${MESSAGE} ${DISCORD_MENTIONS}\",
      \"embeds\": [$embed]
    }" "${WEBHOOK}"
fi

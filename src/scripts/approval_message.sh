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
  
  # Prepare JSON data without using sed
  content=$(jq -n --arg message "$MESSAGE" --arg mentions "$DISCORD_MENTIONS" '{$content: $message + " " + $mentions}')
  description=$(jq -n --arg message "$MESSAGE" --arg url "$URL" '{$description: $message + " - " + $url}')
  fields="["
  if [[ "${INCLUDE_PROJECT_FIELD}" == "true" ]]; then
    fields+="$(jq -n --arg project "$CIRCLE_PROJECT_REPONAME" '{$name: "Project", $value: $project, $inline: true}')"
    if [[ "${INCLUDE_JOB_NUMBER_FIELD}" == "true" ]]; then
      fields+=","
    fi
  fi
  if [[ "${INCLUDE_JOB_NUMBER_FIELD}" == "true" ]]; then
    fields+="$(jq -n --arg jobNumber "$CIRCLE_BUILD_NUM" '{$name: "Job Number", $value: $jobNumber, $inline: true}')"
  fi
  fields+="]"
  embed=$(jq -n --argjson fields "$fields" --argjson color "$COLOR" "{$description, $color, $fields}")

  # Send the request
  curl -X POST -H 'Content-type: application/json' \
    --data \
    "{
      \"content\": $content,
      \"embeds\": [$embed]
    }" "${WEBHOOK}"
  echo "Awaiting approval notified."
fi

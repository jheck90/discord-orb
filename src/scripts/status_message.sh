#!/bin/bash

CURRENT_BRANCH_IN_FILTER=false

IFS="," read -ra BRANCH_FILTERS <<< "${ONLY_FOR_BRANCHES}"
echo "Branch Filters: ${BRANCH_FILTERS[*]}" # Debugging message

for i in "${BRANCH_FILTERS[*]}"; do
  if [ "${i}" == "${CIRCLE_BRANCH}" ]; then
    CURRENT_BRANCH_IN_FILTER=true
  fi
done

echo "Current Branch: ${CIRCLE_BRANCH}" # Debugging message
echo "Current Branch in Filter: ${CURRENT_BRANCH_IN_FILTER}" # Debugging message

if [ "" == "${ONLY_FOR_BRANCHES}" ] || [ "$CURRENT_BRANCH_IN_FILTER" = true ]; then
  # Provide error if no webhook is set and error. Otherwise continue
  if [ -z "${WEBHOOK}" ]; then
    echo "NO DISCORD WEBHOOK SET"
    echo "Please input your DISCORD_WEBHOOK value either in the settings for this project, or as a parameter for this orb."
    exit 1
  else
    echo "Webhook: ${WEBHOOK}" # Debugging message

    # If successful
    if [ "${DISCORD_BUILD_STATUS}" = "SUCCESS" ]; then
      # Skip if fail_only
      if [ "${FAIL_ONLY}" = true ]; then
        echo "The job completed successfully"
        echo '"fail_only" is set to "true". No Discord notification sent.'
      else
        # Create Members string
        if [ -n "${SUCCESS_MENTIONS}" ]; then
          IFS="," read -ra DISCORD_MEMBERS <<< "${SUCCESS_MENTIONS}"
          DISCORD_MENTIONS=""
          for i in "${DISCORD_MEMBERS[@]}"; do
            if echo "${i}" | grep -E "^(here|everyone)$" > /dev/null; then
              DISCORD_MENTIONS="${DISCORD_MENTIONS}@${i} "
            else
              DISCORD_MENTIONS="${DISCORD_MENTIONS}<@${i}> "
            fi
          done
        fi
        echo "Success Mentions: ${DISCORD_MENTIONS}" # Debugging message

        curl -X POST -H 'Content-type: application/json' \
          --data \
            "{ \
              \"content\": \"${SUCCESS_MESSAGE} ${DISCORD_MENTIONS}\", \
              \"embeds\": [{ \
                \"description\": \"${SUCCESS_MESSAGE} ${CIRCLE_BUILD_URL}\", \
                \"color\": \"1883971\", \
                \"fields\": [ \
                  { \
                    \"name\": \"Project\", \
                    \"value\": \"${CIRCLE_PROJECT_REPONAME}\", \
                    \"inline\": true \
                  }, \
                  { \
                    \"name\": \"Job Number\", \
                    \"value\": \"${CIRCLE_BUILD_NUM}\", \
                    \"inline\": true \
                  } \
                ] \
              }] \
            }" "${WEBHOOK}"
        echo "Job completed successfully. Alert sent."
      fi
    else
      # If Failed

      # Skip if success_only
      if [ "${SUCCESS_ONLY}" = true ]; then
        echo "The job failed"
        echo '"success_only" is set to "true". No Discord notification sent.'
      else
        # Create Members string
        if [ -n "${FAILURE_MENTIONS}" ]; then
          IFS="," read -ra DISCORD_MEMBERS <<< "${FAILURE_MENTIONS}"
          DISCORD_MENTIONS=""
          for i in "${DISCORD_MEMBERS[@]}"; do
            if echo "${i}" | grep -E "^(here|everyone)$" > /dev/null; then
              DISCORD_MENTIONS="${DISCORD_MENTIONS}@${i} "
            else
              DISCORD_MENTIONS="${DISCORD_MENTIONS}<@${i}> "
            fi
          done
        fi
        echo "Failure Mentions: ${DISCORD_MENTIONS}" # Debugging message

        curl -X POST -H 'Content-type: application/json' \
          --data \
            "{ \
              \"content\": \"${FAILURE_MESSAGE} ${DISCORD_MENTIONS}\", \
              \"embeds\": [{ \
                \"description\": \"${FAILURE_MESSAGE} ${CIRCLE_BUILD_URL}\", \
                \"color\": \"15555676\", \
                \"fields\": [ \
                  { \
                    \"name\": \"Project\", \
                    \"value\": \"${CIRCLE_PROJECT_REPONAME}\", \
                    \"inline\": true \
                  }, \
                  { \
                    \"name\": \"Job Number\", \
                    \"value\": \"${CIRCLE_BUILD_NUM}\", \
                    \"inline\": true \
                  } \
                ] \
              }] \
            }" "${WEBHOOK}"
        echo "Job failed. Alert sent."
      fi
    fi
  fi
else
  echo "Current branch is not included in only_for_branches filter; no status alert will be sent"
fi

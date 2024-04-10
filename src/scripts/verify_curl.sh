#!/bin/bash

which curl > curl_exists; echo $? | grep -q '1' && echo curl not installed && rm curl_exists && exit 1
rm curl_exists
#!/bin/bash

set -euo pipefail

if [ $(netstat --listening --numeric --tcp | grep --count 32000) -lt 1 ]
then
    exit 1
fi
if [ $(netstat --listening --numeric --tcp | grep --count ${BILLING_PORT}) -lt 1 ]
then
    exit 1
fi

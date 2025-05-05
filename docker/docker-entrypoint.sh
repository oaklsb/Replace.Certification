#!/bin/bash

set -euo pipefail

BILLING_IP=$(hostname --ip-address)

envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < "Config/Certification.xml.template" > "Config/Certification.xml"

exec ./Replace.Certification

#!/usr/bin/env bash
set -euo pipefail

ALLOWANCE="${ALLOWANCE:-300}"

for fixture in Tests/Fixtures/*.json; do
  echo "----"
  scripts/phase0_verify.swift "${fixture}" "${ALLOWANCE}"
done

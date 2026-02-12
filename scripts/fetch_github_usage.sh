#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${GITHUB_USERNAME:-}" ]]; then
  echo "Missing GITHUB_USERNAME env var." >&2
  exit 1
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "Missing GITHUB_TOKEN env var." >&2
  exit 1
fi

YEAR="${YEAR:-$(date -u +%Y)}"
MONTH="${MONTH:-$(date -u +%-m)}"
OUT_FILE="${OUT_FILE:-Tests/Fixtures/github-usage-live-${YEAR}-${MONTH}.json}"

mkdir -p "$(dirname "${OUT_FILE}")"

URL="https://api.github.com/users/${GITHUB_USERNAME}/settings/billing/premium_request/usage?year=${YEAR}&month=${MONTH}"

curl -sS \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "${URL}" \
  -o "${OUT_FILE}"

echo "Saved response to ${OUT_FILE}"

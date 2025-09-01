#!/bin/bash

# Test webhook for PR #8 being MERGED
DEV_API_URL="https://falcon-api.app.gopebble.com/api"
SERVICE_TOKEN="APWC6YY0Q7mkg36U8XRs_UXTwaWXSCtnlKbVRTrtSivb2kUzdkzioZFN0R76io9lYUN32MAKXLAd3H0y"

INSTALLATION_ID=82916268
PR_NUMBER=8

echo "Testing webhook for PR #8 MERGED..."
echo "===================================="

WEBHOOK_PAYLOAD='{
  "installation_id": '$INSTALLATION_ID',
  "id": 8000009,
  "action": "closed",
  "number": '$PR_NUMBER',
  "url": "https://github.com/azizdev1999/test-k8s-configs/pull/'$PR_NUMBER'",
  "state": "closed",
  "merged": true,
  "repo_id": 789012,
  "repo_name": "azizdev1999/test-k8s-configs",
  "author": "clusterresourceupdatedev",
  "created_at": "2025-09-01T10:54:13.000Z",
  "updated_at": "2025-09-01T11:05:00.000Z",
  "merged_at": "2025-09-01T11:05:00.000Z",
  "merged_by": "azizdev1999"
}'

echo "Sending MERGED webhook..."
curl -X POST "$DEV_API_URL/pr-ops/webhooks/github/pull-requests" \
  -H "Authorization: Bearer $SERVICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$WEBHOOK_PAYLOAD" \
  -w "\nHTTP Status: %{http_code}\n"

sleep 2

echo -e "\nChecking PR #8 status..."
mongosh "mongodb://ecoagentuser:G9KnWA8tnisDPli@54.241.154.19:27017/ecoagent_dev" \
  --eval "db.pr_ops_pull_requests.findOne({pr_number: $PR_NUMBER}, {pr_number: 1, status: 1, pr_status: 1, updated_at: 1, _id: 0})" \
  --quiet

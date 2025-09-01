#!/bin/bash

echo "PROOF TEST: Sending webhook with null values to trigger panic"
echo "=============================================================="
echo ""

# Webhook with null values that will cause panic
WEBHOOK_PAYLOAD='{
  "action": "closed",
  "number": 999,
  "pull_request": {
    "id": 999999,
    "number": 999,
    "state": "closed",
    "title": "Test PR to prove panic",
    "user": {
      "login": "testuser"
    },
    "html_url": "https://github.com/test/repo/pull/999",
    "created_at": "2025-09-01T10:00:00Z",
    "updated_at": "2025-09-01T11:00:00Z",
    "closed_at": "2025-09-01T11:00:00Z",
    "merged_at": null,
    "merged": false,
    "merged_by": null,
    "comments": 0,
    "commits": 1,
    "additions": 10,
    "deletions": 5,
    "changed_files": 1
  },
  "repository": {
    "id": 789012,
    "full_name": "test/repo"
  },
  "installation": {
    "id": 83795326
  }
}'

WEBHOOK_SECRET="APWC6YY0Q7mkj36U8XRs_UXTwaWBSCtnlKbVRTrtSivb2kUzdkzioZlN0R74io9lYUN53MAKXLAd3H0y"
SIGNATURE=$(echo -n "$WEBHOOK_PAYLOAD" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | sed 's/^.* //')

echo "1. Sending webhook to local recomm-pr-create..."
curl -X POST http://localhost:8081/public/webhook \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: pull_request" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -d "$WEBHOOK_PAYLOAD" \
  -w "\nHTTP Status: %{http_code}\n"

echo ""
echo "2. Waiting for goroutine to process..."
sleep 3

echo ""
echo "3. Check if webhook was forwarded to pebble-agent-manager..."
echo "   (If panic occurred, no webhook will be received)"

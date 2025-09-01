#!/bin/bash

echo "Testing EXACT conditions like PR #8 in dev"
echo "==========================================="

# Simulate what GitHub sends for PR #8 being closed
WEBHOOK_PAYLOAD='{
  "action": "closed",
  "number": 8,
  "pull_request": {
    "id": 2000008,
    "number": 8,
    "state": "closed",
    "title": "Optimize konnectivity-agent resource allocation",
    "user": {
      "login": "clusterresourceupdatedev[bot]"
    },
    "html_url": "https://github.com/azizdev1999/test-k8s-configs/pull/8",
    "created_at": "2025-09-01T10:54:13.442Z",
    "updated_at": "2025-09-01T11:40:00Z",
    "closed_at": "2025-09-01T11:40:00Z",
    "merged_at": null,
    "merged": false,
    "merged_by": null
  },
  "repository": {
    "id": 847869289,
    "full_name": "azizdev1999/test-k8s-configs"
  },
  "installation": {
    "id": 83795326
  }
}'

# Send to LOCAL recomm-pr-create
WEBHOOK_SECRET="APWC6YY0Q7mkj36U8XRs_UXTwaWBSCtnlKbVRTrtSivb2kUzdkzioZlN0R74io9lYUN53MAKXLAd3H0y"
SIGNATURE=$(echo -n "$WEBHOOK_PAYLOAD" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | sed 's/^.* //')

echo "1. Sending to LOCAL recomm-pr-create (which forwards to LOCAL pebble-agent-manager)..."
curl -X POST http://localhost:8081/public/webhook \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: pull_request" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -d "$WEBHOOK_PAYLOAD" \
  -w "\nHTTP Status: %{http_code}\n"

sleep 2

echo -e "\n2. Check LOCAL pebble-agent-manager logs..."
echo "   Should see webhook received"

echo -e "\n3. Now send same to DEV recomm-pr-create..."
curl -X POST http://a45747eda3b034438b4ba6fedd64516f-901326540.us-west-1.elb.amazonaws.com/public/webhook \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: pull_request" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -d "$WEBHOOK_PAYLOAD" \
  -w "\nHTTP Status: %{http_code}\n"

sleep 2

echo -e "\n4. Check if PR #8 was updated in dev database..."
mongosh "mongodb://ecoagentuser:G9KnWA8tnisDPli@54.241.154.19:27017/ecoagent_dev" \
  --eval "db.pr_ops_pull_requests.findOne({pr_number: 8}, {pr_number: 1, status: 1, pr_status: 1, updated_at: 1, _id: 0})" \
  --quiet

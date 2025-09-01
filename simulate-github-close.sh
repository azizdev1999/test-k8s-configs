#!/bin/bash

echo "Simulating what GitHub SHOULD send when PR #8 is closed:"
echo "=========================================================="

# This simulates GitHub → recomm-pr-create
RECOMM_URL="http://a45747eda3b034438b4ba6fedd64516f-901326540.us-west-1.elb.amazonaws.com"
WEBHOOK_SECRET="APWC6YY0Q7mkj36U8XRs_UXTwaWBSCtnlKbVRTrtSivb2kUzdkzioZlN0R74io9lYUN53MAKXLAd3H0y"

WEBHOOK_PAYLOAD='{
  "action": "closed",
  "number": 8,
  "pull_request": {
    "id": 2000008,
    "number": 8,
    "state": "closed",
    "title": "Optimize konnectivity-agent resource allocation",
    "user": {
      "login": "clusterresourceupdatedev"
    },
    "html_url": "https://github.com/azizdev1999/test-k8s-configs/pull/8",
    "created_at": "2025-09-01T10:54:13.000Z",
    "updated_at": "2025-09-01T11:30:00Z",
    "closed_at": "2025-09-01T11:30:00Z",
    "merged_at": null,
    "merged": false,
    "merged_by": null
  },
  "repository": {
    "id": 789012,
    "full_name": "azizdev1999/test-k8s-configs"
  },
  "installation": {
    "id": 83795326
  }
}'

SIGNATURE=$(echo -n "$WEBHOOK_PAYLOAD" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | sed 's/^.* //')

echo "Sending to recomm-pr-create (like GitHub would)..."
curl -X POST "$RECOMM_URL/public/webhook" \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: pull_request" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -d "$WEBHOOK_PAYLOAD" \
  -w "\nHTTP Status: %{http_code}\n"

sleep 3

echo -e "\nChecking if PR was updated..."
mongosh "mongodb://ecoagentuser:G9KnWA8tnisDPli@54.241.154.19:27017/ecoagent_dev" \
  --eval "db.pr_ops_pull_requests.findOne({pr_number: 8}, {pr_number: 1, status: 1, pr_status: 1, updated_at: 1, _id: 0})" \
  --quiet

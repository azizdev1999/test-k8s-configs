#!/bin/bash

echo "================================================================================================"
echo "FULL LOCAL TEST: recomm-pr-create → pebble-agent-manager → MongoDB"
echo "================================================================================================"
echo ""

# Configuration
INSTALLATION_ID="83795326"
WEBHOOK_SECRET="APWC6YY0Q7mkj36U8XRs_UXTwaWBSCtnlKbVRTrtSivb2kUzdkzioZlN0R74io9lYUN53MAKXLAd3H0y"
LOCAL_RECOMM="http://localhost:8081"
LOCAL_PEBBLE="http://localhost:4001"

echo "Configuration:"
echo "  Installation ID: $INSTALLATION_ID"
echo "  Local recomm-pr-create: $LOCAL_RECOMM"
echo "  Local pebble-agent-manager: $LOCAL_PEBBLE"
echo ""

# Check services are running
echo "1. Checking services..."
echo -n "   recomm-pr-create: "
curl -s http://localhost:8081/public/health > /dev/null 2>&1 && echo "✅ Running" || echo "❌ Not running"

echo -n "   pebble-agent-manager: "
curl -s http://localhost:4001/api/health > /dev/null 2>&1 && echo "✅ Running" || echo "❌ Not running"
echo ""

# Test PR opened webhook
echo "2. Testing PR #8 OPENED webhook..."
WEBHOOK_OPENED='{
  "action": "opened",
  "number": 8,
  "pull_request": {
    "id": 2000008,
    "number": 8,
    "state": "open",
    "title": "Optimize konnectivity-agent resource allocation",
    "user": {
      "login": "clusterresourceupdatedev[bot]"
    },
    "html_url": "https://github.com/azizdev1999/test-k8s-configs/pull/8",
    "created_at": "2025-09-01T10:54:13.000Z",
    "updated_at": "2025-09-01T12:00:00Z",
    "closed_at": null,
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
    "id": 847869289,
    "full_name": "azizdev1999/test-k8s-configs"
  },
  "installation": {
    "id": '$INSTALLATION_ID'
  }
}'

SIGNATURE=$(echo -n "$WEBHOOK_OPENED" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | sed 's/^.* //')

echo "   Sending to local recomm-pr-create..."
RESPONSE=$(curl -s -X POST "$LOCAL_RECOMM/public/webhook" \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: pull_request" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -d "$WEBHOOK_OPENED" \
  -w "\n{\"http_code\": %{http_code}}")

HTTP_CODE=$(echo "$RESPONSE" | grep -o '"http_code": [0-9]*' | grep -o '[0-9]*')
echo "   Response: HTTP $HTTP_CODE"

sleep 2

# Check PR status in database
echo ""
echo "3. Checking PR #8 status in MongoDB..."
mongosh "mongodb://ecoagentuser:G9KnWA8tnisDPli@54.241.154.19:27017/ecoagent_dev" \
  --eval "db.pr_ops_pull_requests.findOne({pr_number: 8}, {pr_number: 1, status: 1, pr_status: 1, updated_at: 1, _id: 0})" \
  --quiet | jq '.'

# Test PR closed webhook
echo ""
echo "4. Testing PR #8 CLOSED webhook..."
WEBHOOK_CLOSED='{
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
    "created_at": "2025-09-01T10:54:13.000Z",
    "updated_at": "2025-09-01T12:05:00Z",
    "closed_at": "2025-09-01T12:05:00Z",
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
    "id": 847869289,
    "full_name": "azizdev1999/test-k8s-configs"
  },
  "installation": {
    "id": '$INSTALLATION_ID'
  }
}'

SIGNATURE=$(echo -n "$WEBHOOK_CLOSED" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | sed 's/^.* //')

echo "   Sending to local recomm-pr-create..."
RESPONSE=$(curl -s -X POST "$LOCAL_RECOMM/public/webhook" \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: pull_request" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -d "$WEBHOOK_CLOSED" \
  -w "\n{\"http_code\": %{http_code}}")

HTTP_CODE=$(echo "$RESPONSE" | grep -o '"http_code": [0-9]*' | grep -o '[0-9]*')
echo "   Response: HTTP $HTTP_CODE"

sleep 2

# Check updated PR status
echo ""
echo "5. Checking updated PR #8 status in MongoDB..."
mongosh "mongodb://ecoagentuser:G9KnWA8tnisDPli@54.241.154.19:27017/ecoagent_dev" \
  --eval "db.pr_ops_pull_requests.findOne({pr_number: 8}, {pr_number: 1, status: 1, pr_status: 1, updated_at: 1, _id: 0})" \
  --quiet | jq '.'

# Test PR merged webhook
echo ""
echo "6. Testing PR #8 MERGED webhook..."
WEBHOOK_MERGED='{
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
    "created_at": "2025-09-01T10:54:13.000Z",
    "updated_at": "2025-09-01T12:10:00Z",
    "closed_at": "2025-09-01T12:10:00Z",
    "merged_at": "2025-09-01T12:10:00Z",
    "merged": true,
    "merged_by": {
      "login": "azizdev1999"
    },
    "comments": 2,
    "commits": 1,
    "additions": 10,
    "deletions": 5,
    "changed_files": 1
  },
  "repository": {
    "id": 847869289,
    "full_name": "azizdev1999/test-k8s-configs"
  },
  "installation": {
    "id": '$INSTALLATION_ID'
  }
}'

SIGNATURE=$(echo -n "$WEBHOOK_MERGED" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | sed 's/^.* //')

echo "   Sending to local recomm-pr-create..."
RESPONSE=$(curl -s -X POST "$LOCAL_RECOMM/public/webhook" \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: pull_request" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -d "$WEBHOOK_MERGED" \
  -w "\n{\"http_code\": %{http_code}}")

HTTP_CODE=$(echo "$RESPONSE" | grep -o '"http_code": [0-9]*' | grep -o '[0-9]*')
echo "   Response: HTTP $HTTP_CODE"

sleep 2

# Final check
echo ""
echo "7. Final PR #8 status in MongoDB (should show merged)..."
mongosh "mongodb://ecoagentuser:G9KnWA8tnisDPli@54.241.154.19:27017/ecoagent_dev" \
  --eval "db.pr_ops_pull_requests.findOne({pr_number: 8}, {pr_number: 1, status: 1, pr_status: 1, is_merged: 1, updated_at: 1, _id: 0})" \
  --quiet | jq '.'

echo ""
echo "================================================================================================"
echo "TEST COMPLETE"
echo "================================================================================================"
echo ""
echo "Expected results:"
echo "  - PR #8 status should change: open → closed → merged"
echo "  - All webhooks should return HTTP 200"
echo "  - MongoDB should reflect the current state"
echo ""
echo "To verify GitHub webhook configuration:"
echo "  1. Go to: https://github.com/settings/apps/clusterresourceupdatedev"
echo "  2. Check webhook URL is: http://a45747eda3b034438b4ba6fedd64516f-901326540.us-west-1.elb.amazonaws.com/public/webhook"
echo "  3. Ensure 'Pull requests' events are enabled"
echo "  4. Check recent deliveries for any failures"
#!/bin/bash

echo "================================================================================================"
echo "FULL LOCAL GITHUB APP TEST - Testing recomm-pr-create with GitHub API"
echo "================================================================================================"
echo ""

# Configuration
GITHUB_APP_ID="1735779"
INSTALLATION_ID="83795326"
REPO_OWNER="azizdev1999"
REPO_NAME="test-k8s-configs"
LOCAL_RECOMM_URL="http://localhost:8081"
WEBHOOK_SECRET="APWC6YY0Q7mkj36U8XRs_UXTwaWBSCtnlKbVRTrtSivb2kUzdkzioZlN0R74io9lYUN53MAKXLAd3H0y"

echo "Test Configuration:"
echo "  GitHub App ID: $GITHUB_APP_ID"
echo "  Installation ID: $INSTALLATION_ID"
echo "  Repository: $REPO_OWNER/$REPO_NAME"
echo "  Local recomm-pr-create: $LOCAL_RECOMM_URL"
echo ""

# Test 1: Health check
echo "1. Testing recomm-pr-create health endpoint..."
curl -s http://localhost:8081/health | jq '.' || echo "recomm-pr-create not running!"
echo ""

# Test 2: Create a test PR via GitHub API (using recomm-pr-create)
echo "2. Creating a test PR via recomm-pr-create API..."
PR_PAYLOAD='{
  "installation_id": '$INSTALLATION_ID',
  "repo_owner": "'$REPO_OWNER'",
  "repo_name": "'$REPO_NAME'",
  "head_branch": "test-pr-ops-'$(date +%s)'",
  "base_branch": "main",
  "title": "Test PR from local testing - '$(date +"%Y-%m-%d %H:%M:%S")'",
  "body": "This is a test PR created locally to verify GitHub App integration.\n\n- Testing local recomm-pr-create\n- Verifying GitHub API access\n- Installation ID: '$INSTALLATION_ID'",
  "files": [
    {
      "path": "test-deployment.yaml",
      "content": "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: test-deployment\n  namespace: default\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app: test\n  template:\n    metadata:\n      labels:\n        app: test\n    spec:\n      containers:\n      - name: test\n        image: nginx:latest\n        resources:\n          requests:\n            cpu: 10m\n            memory: 20Mi"
    }
  ]
}'

echo "Sending PR creation request to local recomm-pr-create..."
PR_RESPONSE=$(curl -s -X POST "$LOCAL_RECOMM_URL/api/v1/github/create-pr" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer APWC6YY0Q7mkg36U8XRs_UXTwaWXSCtnlKbVRTrtSivb2kUzdkzioZFN0R76io9lYUN32MAKXLAd3H0y" \
  -d "$PR_PAYLOAD")

echo "Response:"
echo "$PR_RESPONSE" | jq '.' 2>/dev/null || echo "$PR_RESPONSE"
echo ""

# Extract PR number if created
PR_NUMBER=$(echo "$PR_RESPONSE" | jq -r '.pull_request.number' 2>/dev/null)

if [ "$PR_NUMBER" != "null" ] && [ -n "$PR_NUMBER" ]; then
    echo "✅ Successfully created PR #$PR_NUMBER"
    echo "   URL: https://github.com/$REPO_OWNER/$REPO_NAME/pull/$PR_NUMBER"
    echo ""
    
    # Test 3: Simulate GitHub webhook for the created PR
    echo "3. Simulating GitHub webhook for PR #$PR_NUMBER..."
    
    # Webhook for PR opened
    WEBHOOK_OPENED='{
      "action": "opened",
      "number": '$PR_NUMBER',
      "pull_request": {
        "id": '$((2000000 + PR_NUMBER))',
        "number": '$PR_NUMBER',
        "state": "open",
        "title": "Test PR from local testing",
        "user": {
          "login": "clusterresourceupdatedev[bot]"
        },
        "html_url": "https://github.com/'$REPO_OWNER'/'$REPO_NAME'/pull/'$PR_NUMBER'",
        "created_at": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
        "updated_at": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
        "closed_at": null,
        "merged_at": null,
        "merged": false,
        "merged_by": null,
        "comments": 0,
        "commits": 1,
        "additions": 10,
        "deletions": 0,
        "changed_files": 1
      },
      "repository": {
        "id": 847869289,
        "full_name": "'$REPO_OWNER'/'$REPO_NAME'"
      },
      "installation": {
        "id": '$INSTALLATION_ID'
      }
    }'
    
    SIGNATURE=$(echo -n "$WEBHOOK_OPENED" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | sed 's/^.* //')
    
    echo "Sending webhook to local recomm-pr-create..."
    curl -X POST "$LOCAL_RECOMM_URL/public/webhook" \
      -H "Content-Type: application/json" \
      -H "X-GitHub-Event: pull_request" \
      -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
      -d "$WEBHOOK_OPENED" \
      -w "\nHTTP Status: %{http_code}\n"
    
    sleep 2
    
    # Check if webhook was forwarded to pebble-agent-manager
    echo ""
    echo "4. Checking if webhook was forwarded to pebble-agent-manager..."
    echo "   Check pebble-agent-manager logs for webhook processing"
    
    # Test closing the PR
    echo ""
    echo "5. Simulating PR close webhook..."
    
    WEBHOOK_CLOSED='{
      "action": "closed",
      "number": '$PR_NUMBER',
      "pull_request": {
        "id": '$((2000000 + PR_NUMBER))',
        "number": '$PR_NUMBER',
        "state": "closed",
        "title": "Test PR from local testing",
        "user": {
          "login": "clusterresourceupdatedev[bot]"
        },
        "html_url": "https://github.com/'$REPO_OWNER'/'$REPO_NAME'/pull/'$PR_NUMBER'",
        "created_at": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
        "updated_at": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
        "closed_at": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
        "merged_at": null,
        "merged": false,
        "merged_by": null,
        "comments": 0,
        "commits": 1,
        "additions": 10,
        "deletions": 0,
        "changed_files": 1
      },
      "repository": {
        "id": 847869289,
        "full_name": "'$REPO_OWNER'/'$REPO_NAME'"
      },
      "installation": {
        "id": '$INSTALLATION_ID'
      }
    }'
    
    SIGNATURE=$(echo -n "$WEBHOOK_CLOSED" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | sed 's/^.* //')
    
    curl -X POST "$LOCAL_RECOMM_URL/public/webhook" \
      -H "Content-Type: application/json" \
      -H "X-GitHub-Event: pull_request" \
      -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
      -d "$WEBHOOK_CLOSED" \
      -w "\nHTTP Status: %{http_code}\n"
    
else
    echo "❌ Failed to create PR. Check recomm-pr-create logs for details."
    echo ""
    echo "Possible issues:"
    echo "  1. GitHub App credentials not configured correctly"
    echo "  2. Installation ID mismatch"
    echo "  3. GitHub API rate limits"
    echo "  4. Network connectivity issues"
fi

echo ""
echo "================================================================================================"
echo "TEST COMPLETE"
echo "================================================================================================"
echo ""
echo "Next steps:"
echo "1. Check recomm-pr-create logs for GitHub API interactions"
echo "2. Check pebble-agent-manager logs for webhook forwarding"
echo "3. If PR was created, check: https://github.com/$REPO_OWNER/$REPO_NAME/pulls"
echo "4. Verify PR status in MongoDB:"
echo "   mongosh \"mongodb://ecoagentuser:G9KnWA8tnisDPli@54.241.154.19:27017/ecoagent_dev\" \\"
echo "     --eval \"db.pr_ops_pull_requests.find({}, {pr_number: 1, status: 1, pr_status: 1, _id: 0}).sort({pr_number: -1}).limit(5)\""
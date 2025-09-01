#!/bin/bash

echo "================================================================================================"
echo "TESTING DEV ENDPOINT ACCESSIBILITY"
echo "================================================================================================"
echo ""

DEV_URL="http://a45747eda3b034438b4ba6fedd64516f-901326540.us-west-1.elb.amazonaws.com"

echo "1. Testing basic connectivity to DEV recomm-pr-create..."
echo "   URL: $DEV_URL"
echo ""

# Test 1: Basic connectivity
echo "Test 1: Basic HTTP GET to /public/health"
curl -v -X GET "$DEV_URL/public/health" \
  -H "Accept: application/json" \
  --max-time 10 \
  2>&1 | grep -E "< HTTP|Connected to|Connection|SSL|TLS"

echo ""
echo "Test 2: Sending test webhook (should get 401 due to invalid signature)"
TEST_PAYLOAD='{"test": "connectivity"}'
curl -v -X POST "$DEV_URL/public/webhook" \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: ping" \
  -d "$TEST_PAYLOAD" \
  --max-time 10 \
  2>&1 | grep -E "< HTTP|Connected to|Connection|response"

echo ""
echo "Test 3: DNS resolution"
nslookup a45747eda3b034438b4ba6fedd64516f-901326540.us-west-1.elb.amazonaws.com

echo ""
echo "Test 4: Traceroute (first 5 hops)"
traceroute -m 5 a45747eda3b034438b4ba6fedd64516f-901326540.us-west-1.elb.amazonaws.com 2>/dev/null || echo "Traceroute not available"

echo ""
echo "================================================================================================"
echo "GITHUB WEBHOOK RECENT DELIVERIES CHECK"
echo "================================================================================================"
echo ""
echo "To check exact GitHub errors:"
echo "1. Go to: https://github.com/settings/apps/clusterresourceupdatedev"
echo "2. Click 'Advanced' in the left sidebar"
echo "3. Scroll down to 'Recent Deliveries'"
echo "4. Look for any failed deliveries (marked with ❌)"
echo "5. Click on a failed delivery to see:"
echo "   - Request headers and body"
echo "   - Response status code"
echo "   - Response body with exact error message"
echo "   - Response time"
echo ""
echo "Common GitHub webhook errors:"
echo "  - Connection timeout: Endpoint not reachable"
echo "  - SSL error: Certificate issues"
echo "  - 404: Wrong URL path"
echo "  - 401/403: Authentication/signature mismatch"
echo "  - 500: Server error in recomm-pr-create"
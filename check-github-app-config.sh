#!/bin/bash

echo "================================================================================================"
echo "GITHUB APP WEBHOOK CONFIGURATION CHECK"
echo "================================================================================================"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed. Install it with: brew install gh"
    exit 1
fi

echo "Checking GitHub App configuration..."
echo ""

# Try to get app info using gh CLI
echo "1. Attempting to get GitHub App info via API..."
echo ""

# Create a script to check webhook config
cat > /tmp/check-webhook-config.sh << 'EOF'
#!/bin/bash

# GitHub App webhook configuration URLs
APP_NAME="clusterresourceupdatedev"
EXPECTED_WEBHOOK_URL="http://a45747eda3b034438b4ba6fedd64516f-901326540.us-west-1.elb.amazonaws.com/public/webhook"

echo "GitHub App: $APP_NAME"
echo "Expected webhook URL: $EXPECTED_WEBHOOK_URL"
echo ""
echo "To manually check the webhook configuration:"
echo ""
echo "1. Open in browser: https://github.com/settings/apps/$APP_NAME"
echo ""
echo "2. Check these sections:"
echo "   a) General > Webhook URL"
echo "      Should be: $EXPECTED_WEBHOOK_URL"
echo ""
echo "   b) General > Webhook secret"
echo "      Should match the one in recomm-pr-create .env file"
echo ""
echo "   c) Permissions & events > Subscribe to events"
echo "      Should have these checked:"
echo "      ✓ Pull request"
echo "      ✓ Pull request review"
echo "      ✓ Pull request review comment"
echo ""
echo "3. Click 'Advanced' tab and check 'Recent Deliveries'"
echo "   Look for any with status ❌ (failed)"
echo "   Click on failed deliveries to see:"
echo "   - Request tab: Shows what GitHub sent"
echo "   - Response tab: Shows the error message"
echo ""
echo "Common issues in Recent Deliveries:"
echo "  • 'Connection refused' - Service is down"
echo "  • 'Connection timeout' - Network/firewall issue"
echo "  • 'SSL certificate problem' - HTTPS/TLS issue"
echo "  • '404 Not Found' - Wrong URL path"
echo "  • '401 Unauthorized' - Webhook secret mismatch"
echo "  • 'No response' - Service crashed/timeout"
EOF

bash /tmp/check-webhook-config.sh

echo ""
echo "================================================================================================"
echo "TESTING IF GITHUB CAN REACH THE WEBHOOK"
echo "================================================================================================"
echo ""

# Test with a real GitHub action
echo "To trigger a real webhook from GitHub:"
echo "1. Go to: https://github.com/azizdev1999/test-k8s-configs/pull/8"
echo "2. Add a comment to the PR"
echo "3. Close and reopen the PR"
echo "4. Check Recent Deliveries at: https://github.com/settings/apps/$APP_NAME/advanced"
echo ""

echo "================================================================================================"
echo "DEBUGGING WEBHOOK FAILURES"
echo "================================================================================================"
echo ""
echo "If webhooks are failing in Recent Deliveries:"
echo ""
echo "1. Click on a failed delivery"
echo "2. Look at the 'Response' tab for the exact error"
echo "3. Common errors and solutions:"
echo ""
echo "   Error: 'Connection timeout' or 'Connection refused'"
echo "   → The ELB might be down or not accessible from GitHub"
echo "   → Check: kubectl get svc -n default | grep recomm"
echo ""
echo "   Error: '404 Not Found'"
echo "   → The webhook URL path is wrong"
echo "   → Should be: /public/webhook"
echo ""
echo "   Error: '401 Unauthorized' or 'Invalid signature'"
echo "   → Webhook secret mismatch"
echo "   → Check .env file in recomm-pr-create"
echo ""
echo "   Error: '500 Internal Server Error'"
echo "   → recomm-pr-create is crashing"
echo "   → Check: kubectl logs -n default -l app=recomm-pr-create"
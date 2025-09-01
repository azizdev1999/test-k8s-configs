#!/bin/bash

echo "================================================================================================"
echo "TESTING GITHUB API WITH LOCAL recomm-pr-create"
echo "================================================================================================"
echo ""

# Configuration
GITHUB_APP_ID="1735779"
INSTALLATION_ID="83795326"
REPO_OWNER="azizdev1999"
REPO_NAME="test-k8s-configs"

echo "Configuration:"
echo "  GitHub App ID: $GITHUB_APP_ID"
echo "  Installation ID: $INSTALLATION_ID"
echo "  Repository: $REPO_OWNER/$REPO_NAME"
echo ""

# Test 1: List repositories accessible to the GitHub App
echo "1. Testing GitHub API access - List repositories..."
echo "   This will verify that recomm-pr-create can authenticate with GitHub"
echo ""

# We need to test the GitHub API directly through recomm-pr-create
# Since recomm-pr-create uses the GitHub App authentication

echo "2. Checking if we can access the GitHub API..."
echo "   Testing with installation ID: $INSTALLATION_ID"
echo ""

# Create a simple test to verify GitHub connectivity
cat > /tmp/test-github-api.go << 'EOF'
package main

import (
    "context"
    "fmt"
    "io/ioutil"
    "net/http"
    "time"
    
    "github.com/bradleyfalzon/ghinstallation/v2"
)

func main() {
    // GitHub App configuration
    appID := int64(1735779)
    installationID := int64(83795326)
    privateKeyPath := "/Users/azizbektokhirjonov/Desktop/Projects/main-pebble/recomm-pr-create/key.pem"
    
    // Read private key
    privateKey, err := ioutil.ReadFile(privateKeyPath)
    if err != nil {
        fmt.Printf("❌ Error reading private key: %v\n", err)
        return
    }
    
    // Create GitHub App installation transport
    itr, err := ghinstallation.New(http.DefaultTransport, appID, installationID, privateKey)
    if err != nil {
        fmt.Printf("❌ Error creating installation transport: %v\n", err)
        return
    }
    
    // Create HTTP client with the installation transport
    client := &http.Client{
        Transport: itr,
        Timeout:   10 * time.Second,
    }
    
    // Test API access - Get installation
    fmt.Println("Testing GitHub API access...")
    resp, err := client.Get("https://api.github.com/installation")
    if err != nil {
        fmt.Printf("❌ Error accessing GitHub API: %v\n", err)
        return
    }
    defer resp.Body.Close()
    
    if resp.StatusCode == 200 {
        fmt.Println("✅ Successfully authenticated with GitHub API")
        
        // Try to list repositories
        fmt.Println("\nListing accessible repositories...")
        resp2, err := client.Get("https://api.github.com/installation/repositories?per_page=5")
        if err != nil {
            fmt.Printf("❌ Error listing repositories: %v\n", err)
            return
        }
        defer resp2.Body.Close()
        
        if resp2.StatusCode == 200 {
            body, _ := ioutil.ReadAll(resp2.Body)
            fmt.Println("✅ Successfully listed repositories")
            fmt.Printf("Response preview (first 500 chars):\n%s\n", string(body[:min(500, len(body))]))
        } else {
            fmt.Printf("❌ Failed to list repositories: HTTP %d\n", resp2.StatusCode)
        }
    } else {
        fmt.Printf("❌ Authentication failed: HTTP %d\n", resp.StatusCode)
    }
}

func min(a, b int) int {
    if a < b {
        return a
    }
    return b
}
EOF

echo "3. Running GitHub API test..."
cd /Users/azizbektokhirjonov/Desktop/Projects/main-pebble/recomm-pr-create
go run /tmp/test-github-api.go

echo ""
echo "================================================================================================"
echo "GITHUB WEBHOOK URL VERIFICATION"
echo "================================================================================================"
echo ""
echo "The GitHub App webhook should be configured as:"
echo "  URL: http://a45747eda3b034438b4ba6fedd64516f-901326540.us-west-1.elb.amazonaws.com/public/webhook"
echo ""
echo "To verify/fix:"
echo "  1. Go to: https://github.com/settings/apps/clusterresourceupdatedev"
echo "  2. Click on 'Webhook' in the left sidebar"
echo "  3. Check the Webhook URL field"
echo "  4. Ensure 'Pull requests' is checked under 'Subscribe to events'"
echo "  5. Check 'Recent Deliveries' tab for any failed webhooks"
echo ""
echo "If webhooks are failing:"
echo "  - Check if the DEV ELB is accessible from GitHub"
echo "  - Verify the webhook secret matches"
echo "  - Look for HTTP errors in Recent Deliveries"
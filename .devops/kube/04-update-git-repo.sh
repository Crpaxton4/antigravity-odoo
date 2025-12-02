#!/bin/bash
# Script to update Git repository URL in Flux sources

set -e

echo "=========================================="
echo "Update Git Repository URL"
echo "=========================================="
echo ""

GIT_REPO_FILE="kubernetes/flux/sources/gitrepository.yaml"

# Get current URL
CURRENT_URL=$(grep "url:" "$GIT_REPO_FILE" | sed 's/.*url: //')

echo "Current configuration:"
echo "  url: $CURRENT_URL"
echo ""

# Use argument if provided, otherwise prompt
if [ -n "$1" ]; then
    GIT_URL="$1"
else
    read -p "Enter your Git repository URL (Press Enter to keep current): " GIT_URL
fi

# If empty, keep current
if [ -z "$GIT_URL" ]; then
    echo "Using current URL: $CURRENT_URL"
    GIT_URL="$CURRENT_URL"
fi

# Update the URL
sed -i.bak "s|url: .*|url: $GIT_URL|" "$GIT_REPO_FILE"
rm -f "$GIT_REPO_FILE.bak"

echo ""
echo "✓ Updated Git repository URL to: $GIT_URL"
echo ""

echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Deploy services:"
echo "   ./06-deploy.sh"
echo ""
 
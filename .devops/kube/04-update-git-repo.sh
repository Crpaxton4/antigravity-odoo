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
    echo "✓ Keeping current URL: $CURRENT_URL"
    exit 0
fi

# Normalize URLs for comparison (remove .git suffix if present)
NORMALIZED_CURRENT=$(echo "$CURRENT_URL" | sed 's/\.git$//')
NORMALIZED_INPUT=$(echo "$GIT_URL" | sed 's/\.git$//')

# Check if URL is already set correctly
if [ "$NORMALIZED_CURRENT" == "$NORMALIZED_INPUT" ]; then
    echo "✓ Git repository URL is already set to: $CURRENT_URL"
    echo "No changes needed."
    exit 0
fi

echo ""
echo "Changing URL from:"
echo "  Old: $CURRENT_URL"
echo "  New: $GIT_URL"
echo ""
read -p "Continue? (Y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Cancelled. Keeping current URL."
    exit 0
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
 
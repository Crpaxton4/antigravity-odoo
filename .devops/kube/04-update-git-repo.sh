#!/bin/bash
# Script to update Git repository URL in Flux sources

set -e

echo "=========================================="
echo "Update Git Repository URL"
echo "=========================================="
echo ""

GIT_REPO_FILE="kubernetes/flux/sources/gitrepository.yaml"

echo "Current configuration:"
grep "url:" "$GIT_REPO_FILE"
echo ""

read -p "Enter your Git repository URL (e.g., https://github.com/username/antigravity-odoo): " GIT_URL

if [ -z "$GIT_URL" ]; then
    echo "❌ No URL provided. Exiting."
    exit 1
fi

# Update the URL
sed -i.bak "s|url: .*|url: $GIT_URL|" "$GIT_REPO_FILE"
rm -f "$GIT_REPO_FILE.bak"

echo ""
echo "✓ Updated Git repository URL to: $GIT_URL"
echo ""

# Check if repo is private
echo "Is this a private repository?"
read -p "(y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "For private repositories, you'll need to create a secret:"
    echo ""
    echo "  kubectl create secret generic git-credentials \\"
    echo "    --from-literal=username=YOUR_USERNAME \\"
    echo "    --from-literal=password=YOUR_PERSONAL_ACCESS_TOKEN \\"
    echo "    --namespace=flux-system"
    echo ""
    echo "Then uncomment the secretRef section in $GIT_REPO_FILE"
    echo ""
fi

echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Install Flux CD:"
echo "   ./05-install-flux.sh"
echo ""
echo "2. Deploy services:"
echo "   ./06-deploy.sh"
echo ""

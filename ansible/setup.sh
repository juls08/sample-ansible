# Quick Setup Script
# This script helps you get started quickly with Ansible deployment

#!/bin/bash

set -e

echo "============================================"
echo "PAGASA Weather Demo - Ansible Setup Helper"
echo "============================================"
echo ""

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible is not installed"
    echo "Please install Ansible first:"
    echo "  Ubuntu/Debian: sudo apt install ansible"
    echo "  macOS: brew install ansible"
    echo "  Pip: pip install ansible"
    exit 1
fi

echo "✓ Ansible is installed: $(ansible --version | head -n1)"

# Install required collections
echo ""
echo "Installing required Ansible collections..."
ansible-galaxy collection install -r requirements.yml

echo ""
echo "✓ Required collections installed"

# Check inventory
echo ""
echo "Checking inventory configuration..."
if grep -q "your-staging-server-ip" inventory/staging; then
    echo "⚠️  Please update inventory/staging with your actual server IP"
    echo "   Edit: inventory/staging"
else
    echo "✓ Inventory appears to be configured"
fi

# Check variables
echo ""
echo "Checking variables configuration..."
if grep -q "change_me" group_vars/staging.yml; then
    echo "⚠️  Please update passwords in group_vars/staging.yml"
    echo "   Edit: group_vars/staging.yml"
else
    echo "✓ Variables appear to be configured"
fi

echo ""
echo "============================================"
echo "Next Steps:"
echo "============================================"
echo ""
echo "1. Update your server details:"
echo "   nano inventory/staging"
echo ""
echo "2. Update passwords and secrets:"
echo "   nano group_vars/staging.yml"
echo ""
echo "3. Test connection:"
echo "   ansible all -i inventory/staging -m ping"
echo ""
echo "4. Run full deployment:"
echo "   ansible-playbook -i inventory/staging playbooks/site.yml"
echo ""
echo "5. Or deploy step by step:"
echo "   ansible-playbook -i inventory/staging playbooks/provision.yml"
echo "   ansible-playbook -i inventory/staging playbooks/deploy.yml"
echo "   ansible-playbook -i inventory/staging playbooks/monitoring.yml"
echo ""
echo "For more details, see: README.md"
echo "============================================"

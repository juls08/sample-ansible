# Ansible Deployment Makefile
# Convenient commands for common Ansible operations

.PHONY: help install test-staging test-prod provision-staging provision-prod deploy-staging deploy-prod monitor-staging monitor-prod full-staging full-prod

# Default environment
ENV ?= staging
INVENTORY = inventory/$(ENV)

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install Ansible dependencies
	@echo "Installing Ansible collections..."
	ansible-galaxy collection install -r requirements.yml
	@echo "✓ Dependencies installed"

test-staging: ## Test connection to staging servers
	ansible all -i inventory/staging -m ping

test-prod: ## Test connection to production servers
	ansible all -i inventory/production -m ping

provision-staging: ## Provision staging servers (install Docker, configure system)
	ansible-playbook -i inventory/staging playbooks/provision.yml

provision-prod: ## Provision production servers
	ansible-playbook -i inventory/production playbooks/provision.yml

deploy-staging: ## Deploy application to staging
	ansible-playbook -i inventory/staging playbooks/deploy.yml

deploy-prod: ## Deploy application to production
	ansible-playbook -i inventory/production playbooks/deploy.yml

monitor-staging: ## Deploy monitoring stack to staging
	ansible-playbook -i inventory/staging playbooks/monitoring.yml

monitor-prod: ## Deploy monitoring stack to production
	ansible-playbook -i inventory/production playbooks/monitoring.yml

full-staging: ## Complete deployment to staging (provision + app + monitoring)
	ansible-playbook -i inventory/staging playbooks/site.yml

full-prod: ## Complete deployment to production
	ansible-playbook -i inventory/production playbooks/site.yml

check-staging: ## Check staging deployment status
	@echo "Checking staging services..."
	@curl -s http://localhost:8000/health || echo "Backend not reachable"
	@curl -s http://localhost:3000 > /dev/null && echo "✓ Frontend OK" || echo "✗ Frontend not reachable"
	@curl -s http://localhost:9090/-/ready > /dev/null && echo "✓ Prometheus OK" || echo "✗ Prometheus not reachable"
	@curl -s http://localhost:3100/api/health > /dev/null && echo "✓ Grafana OK" || echo "✗ Grafana not reachable"

lint: ## Lint Ansible playbooks
	ansible-playbook --syntax-check playbooks/*.yml
	ansible-lint playbooks/ || true

dry-run-staging: ## Dry run for staging deployment
	ansible-playbook -i inventory/staging playbooks/site.yml --check --diff

dry-run-prod: ## Dry run for production deployment
	ansible-playbook -i inventory/production playbooks/site.yml --check --diff

list-staging: ## List staging hosts
	ansible all -i inventory/staging --list-hosts

list-prod: ## List production hosts
	ansible all -i inventory/production --list-hosts

facts-staging: ## Gather facts from staging servers
	ansible all -i inventory/staging -m setup

logs-staging: ## Show recent logs from staging services
	@echo "Fetching logs from staging..."
	ansible webservers -i inventory/staging -a "docker logs --tail 50 backend" -b
	ansible webservers -i inventory/staging -a "docker logs --tail 50 frontend" -b

clean: ## Clean up temporary Ansible files
	find . -name "*.retry" -delete
	find . -name "*.log" -delete
	rm -rf .ansible/

# Advanced commands
vault-edit-staging: ## Edit encrypted staging variables
	ansible-vault edit group_vars/staging.yml

vault-edit-prod: ## Edit encrypted production variables
	ansible-vault edit group_vars/production.yml

encrypt-staging: ## Encrypt staging variables file
	ansible-vault encrypt group_vars/staging.yml

encrypt-prod: ## Encrypt production variables file
	ansible-vault encrypt group_vars/production.yml

decrypt-staging: ## Decrypt staging variables file
	ansible-vault decrypt group_vars/staging.yml

decrypt-prod: ## Decrypt production variables file
	ansible-vault decrypt group_vars/production.yml

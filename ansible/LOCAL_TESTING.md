# Local Testing Guide

This guide explains how to test the Ansible setup on your local machine before deploying to a remote server.

## Configuration for Local Testing

The staging inventory is now configured to run Ansible locally without SSH:

```ini
[webservers]
staging-server ansible_connection=local

[monitoring]
staging-server

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_connection=local
environment=staging
```

Key changes:
- `ansible_connection=local` - Runs commands directly on local machine (no SSH)
- Removed `ansible_host` and `ansible_user` - Not needed for local connection

## Prerequisites for Local Testing

1. **Install Ansible** (if not already installed):
   ```bash
   # Ubuntu/Debian
   sudo apt update && sudo apt install ansible
   
   # Or via pip
   pip install ansible
   ```

2. **Install Docker and Docker Compose**:
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # Add your user to docker group (avoid using sudo)
   sudo usermod -aG docker $USER
   newgrp docker
   
   # Verify
   docker --version
   docker compose version
   ```

3. **Install Ansible Collections**:
   ```bash
   cd ansible
   ansible-galaxy collection install -r requirements.yml
   # Or
   make install
   ```

## Important Notes for Local Testing

### 1. Running Without Sudo

If you're running on your local machine, you may want to avoid using `become` (sudo) for some tasks:

```bash
# Test without become
ansible-playbook -i inventory/staging playbooks/monitoring.yml --skip-tags="requires_root"
```

### 2. User Permissions

For local testing, you need to ensure your user has proper permissions:

```bash
# Add yourself to docker group (if not already)
sudo usermod -aG docker $USER

# Apply the group change
newgrp docker

# Verify you can run docker without sudo
docker ps
```

### 3. Directory Permissions

The deploy path defaults to `/opt/pagasa-weather-demo`. For local testing, you might want to use a path you own:

Edit `ansible/group_vars/staging.yml`:
```yaml
deploy_path: /home/yourusername/pagasa-weather-demo
# OR use your current directory
# deploy_path: "{{ playbook_dir }}/.."
```

## Testing Steps

### Step 1: Test Connection

```bash
cd ansible

# Test connection (should succeed now)
make test-staging

# Expected output:
# staging-server | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

### Step 2: Test Monitoring Deployment Only

Start with just the monitoring stack:

```bash
# Deploy monitoring only
make monitor-staging

# Or with ansible-playbook
ansible-playbook -i inventory/staging playbooks/monitoring.yml
```

This will:
- Create monitoring directories in `/opt/monitoring`
- Deploy Prometheus, Grafana, Node Exporter, cAdvisor
- Start all monitoring containers

### Step 3: Check Monitoring Services

```bash
# Check if containers are running
docker ps | grep -E "prometheus|grafana|node-exporter|cadvisor"

# Access monitoring UIs
# Grafana: http://localhost:3100
# Prometheus: http://localhost:9090
# Node Exporter: http://localhost:9100/metrics
# cAdvisor: http://localhost:8080
```

### Step 4: Deploy Application (Optional)

If you want to test the full deployment:

```bash
# Update the app_repo in group_vars/staging.yml first
nano group_vars/staging.yml

# Then deploy
make deploy-staging

# Or full deployment
make full-staging
```

## Deployment Options for Local Testing

### Option 1: Monitoring Only (Recommended for First Test)

```bash
# Just deploy the monitoring stack
ansible-playbook -i inventory/staging playbooks/monitoring.yml
```

**What it does:**
- Creates `/opt/monitoring` directory
- Deploys Prometheus, Grafana, Node Exporter, cAdvisor
- Starts monitoring containers
- Sets up dashboards and alerts

**Access:**
- Grafana: http://localhost:3100 (admin/password from group_vars)
- Prometheus: http://localhost:9090

### Option 2: Application Only

```bash
# Deploy just the app (requires app_repo to be set)
ansible-playbook -i inventory/staging playbooks/deploy.yml
```

**What it does:**
- Clones repository to deploy_path
- Creates .env file
- Runs docker compose for app services

**Note:** Update `app_repo` in `group_vars/staging.yml` first!

### Option 3: Full Deployment

```bash
# Complete deployment (provision + app + monitoring)
ansible-playbook -i inventory/staging playbooks/site.yml
```

**What it does:**
- Installs Docker (if not present)
- Configures system settings
- Deploys application
- Deploys monitoring stack

## Troubleshooting Local Testing

### Issue: Variables Undefined in Playbooks

**Symptom:** Error like `'deploy_user' is undefined` when running playbooks from `playbooks/` directory

**Root Cause:** Ansible looks for `group_vars/` relative to the playbook location. When playbooks are in a subdirectory (`playbooks/monitoring.yml`), Ansible searches for `playbooks/group_vars/` which doesn't exist.

**Solution:** Symlink `group_vars` and `inventory` into the playbooks directory:
```bash
cd ansible/playbooks
ln -s ../group_vars group_vars
ln -s ../inventory inventory
```

**Alternative Solution:** Run playbooks from the ansible root directory:
```bash
# Instead of: cd playbooks && ansible-playbook monitoring.yml
# Use: 
cd ansible
ansible-playbook playbooks/monitoring.yml
```

**Verification:** Test variable resolution:
```bash
# Should show the value from all.yml
ansible monitoring -i inventory/staging -m debug -a "var=deploy_user"
```

### Issue: Jinja2 Template Errors with Prometheus/Alertmanager

**Symptom:** Template error with "unexpected char '$'" or "unexpected '.'"

**Root Cause:** Prometheus and Alertmanager use Go template syntax (`{{ $labels.instance }}`, `{{ range .Alerts }}`) which conflicts with Jinja2 syntax.

**Solution:** Wrap Prometheus/Alertmanager template content in `{% raw %}` blocks in the `.j2` files:
```jinja2
---
# Prometheus Alert Rules
{% raw %}
groups:
  - name: system_alerts
    rules:
      - alert: HighCPU
        annotations:
          summary: "High CPU on {{ $labels.instance }}"
{% endraw %}
```

This tells Jinja2 not to process the content inside `{% raw %}...{% endraw %}` blocks.

### Issue: Python Docker Module Not Found

**Symptom:** `No module named 'docker'` or `No module named 'compose'`

**Solution:** Install required Python packages:
```bash
# On Ubuntu/Debian
sudo apt install python3-docker python3-compose

# Or via pip (if not externally-managed)
pip install docker docker-compose
```

### Issue: Permission Denied Errors

**Solution 1:** Ensure your user is in the docker group
```bash
sudo usermod -aG docker $USER
newgrp docker
```

**Solution 2:** Run with become (sudo)
```bash
ansible-playbook -i inventory/staging playbooks/monitoring.yml --ask-become-pass
# The --ask-become-pass flag will prompt for your sudo password
```

### Issue: Cannot Create /opt Directories

**Solution:** Use a path you own

Edit `group_vars/staging.yml`:
```yaml
deploy_path: ~/pagasa-weather-demo
# For monitoring, you'd need to update the role or use a different path
```

Or run with sudo:
```bash
ansible-playbook -i inventory/staging playbooks/monitoring.yml --ask-become-pass
```

### Issue: Port Already in Use

If you're already running the application:

```bash
# Stop existing containers
cd /path/to/pagasa-weather-demo
docker compose down

# Or stop specific containers
docker stop backend frontend prometheus grafana
```

### Issue: Docker Not Found

Install Docker:
```bash
# Using the Docker convenience script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Or manually via Docker role
ansible-playbook -i inventory/staging playbooks/provision.yml
```

### Issue: Cannot Connect to Docker Daemon

```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Check status
sudo systemctl status docker
```

## Customizing for Local Testing

### Use Current Directory Instead of /opt

Edit `ansible/group_vars/staging.yml`:

```yaml
# Use current project directory
deploy_path: "{{ lookup('env', 'PWD') }}"

# Or a specific local path
deploy_path: /home/yourusername/projects/pagasa-weather-demo
```

### Skip Provisioning Tasks

If Docker is already installed, skip provision:

```bash
# Deploy without provisioning
ansible-playbook -i inventory/staging playbooks/deploy.yml
ansible-playbook -i inventory/staging playbooks/monitoring.yml
```

### Test Individual Roles

Test roles independently:

```bash
# Test just the monitoring role
ansible-playbook -i inventory/staging -e "role_name=monitoring" test-role.yml

# Or create a simple playbook
cat > test-monitoring.yml <<EOF
---
- hosts: webservers
  become: yes
  roles:
    - monitoring
EOF

ansible-playbook -i inventory/staging test-monitoring.yml
```

## Minimal Local Test (No Full Deployment)

If you just want to test monitoring without deploying the app:

```bash
# 1. Test connection
make test-staging

# 2. Create monitoring directories manually
sudo mkdir -p /opt/monitoring/{prometheus,grafana,alertmanager}/{data,}
sudo chown -R $USER:$USER /opt/monitoring

# 3. Deploy monitoring
ansible-playbook -i inventory/staging playbooks/monitoring.yml

# 4. Access Grafana
firefox http://localhost:3100 &
```

## Comparing Local vs Remote

| Aspect | Local Testing | Remote Server |
|--------|--------------|---------------|
| Connection | `ansible_connection=local` | SSH |
| User | Current user | `ansible_user=deploy` |
| Become | Optional | Usually required |
| Speed | Instant | Network dependent |
| Safety | Safe to experiment | Use caution |

## Next Steps After Local Testing

Once local testing works:

1. **Update inventory for remote server:**
   ```ini
   [webservers]
   staging-server ansible_host=YOUR_SERVER_IP ansible_user=deploy
   
   [monitoring]
   staging-server
   ```

2. **Set up SSH access:**
   ```bash
   ssh-copy-id deploy@YOUR_SERVER_IP
   ```

3. **Test remote connection:**
   ```bash
   make test-staging
   ```

4. **Deploy to remote:**
   ```bash
   make full-staging
   ```

## Useful Local Testing Commands

```bash
# Ping test
ansible all -i inventory/staging -m ping

# Check facts
ansible all -i inventory/staging -m setup

# Run a command
ansible all -i inventory/staging -m command -a "docker ps"

# Check if Docker is installed
ansible all -i inventory/staging -m command -a "docker --version"

# List running playbook with verbose output
ansible-playbook -i inventory/staging playbooks/monitoring.yml -vv

# Dry run (check mode)
ansible-playbook -i inventory/staging playbooks/monitoring.yml --check

# Step through playbook interactively
ansible-playbook -i inventory/staging playbooks/monitoring.yml --step
```

## Clean Up After Testing

```bash
# Stop and remove all monitoring containers
docker stop prometheus grafana node-exporter cadvisor alertmanager
docker rm prometheus grafana node-exporter cadvisor alertmanager

# Remove monitoring directory
sudo rm -rf /opt/monitoring

# Or use docker compose
cd /opt/monitoring
docker compose down -v
```

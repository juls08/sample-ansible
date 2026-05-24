# Ansible Deployment with Monitoring

This directory contains Ansible playbooks and roles for automating the deployment of the PAGASA Weather Demo application with comprehensive monitoring.

## Overview

The Ansible setup includes:

- **Server Provisioning**: Base system setup, security hardening, and Docker installation
- **Application Deployment**: Automated deployment of backend, frontend, PostgreSQL, and Redis
- **Monitoring Stack**: Prometheus, Grafana, Node Exporter, cAdvisor, and Alertmanager
- **Health Checks**: Automated verification of all services
- **Alerting**: Pre-configured alert rules for system and application monitoring

## Architecture

### Monitoring Components

- **Prometheus**: Metrics collection and alerting engine
- **Grafana**: Visualization dashboards (port 3100)
- **Node Exporter**: System-level metrics (CPU, memory, disk, network)
- **cAdvisor**: Container metrics (Docker resource usage)
- **Alertmanager**: Alert routing and notifications (optional)

### Alert Categories

1. **System Alerts**: CPU, memory, disk usage
2. **Container Alerts**: Container health and resource usage
3. **Application Alerts**: API health, response times, database connections
4. **Monitoring Alerts**: Prometheus/Grafana health

## Prerequisites

### On Your Local Machine

1. **Install Ansible**:
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install ansible

   # macOS
   brew install ansible

   # Or use pip
   pip install ansible
   ```

2. **Install Ansible dependencies**:
   ```bash
   ansible-galaxy collection install community.docker
   ```

3. **Verify installation**:
   ```bash
   ansible --version  # Should be 2.9 or higher
   ```

### On Your Target Server(s)

- Ubuntu 20.04 or 22.04 (Debian-based system)
- SSH access with sudo privileges
- At least 2GB RAM (4GB recommended)
- 20GB disk space minimum

## Quick Start

### 1. Configure Inventory

Edit the inventory file for your environment:

```bash
# For staging
nano inventory/staging

# For production
nano inventory/production
```

Update the server IP address and connection details:
```ini
[webservers]
your-server ansible_host=YOUR_SERVER_IP ansible_user=YOUR_SSH_USER

[monitoring]
your-server
```

### 2. Configure Variables

Edit environment-specific variables:

```bash
nano group_vars/staging.yml
```

Update these critical values:
- `postgres_password`: Database password
- `redis_password`: Redis password
- `app_repo`: Your GitHub repository URL
- `grafana_admin_password`: Grafana admin password

### 3. Test Connection

```bash
ansible all -i inventory/staging -m ping
```

### 4. Deploy Everything

```bash
# Full deployment (provision + app + monitoring)
ansible-playbook -i inventory/staging playbooks/site.yml

# Or step by step:
ansible-playbook -i inventory/staging playbooks/provision.yml
ansible-playbook -i inventory/staging playbooks/deploy.yml
ansible-playbook -i inventory/staging playbooks/monitoring.yml
```

## Playbook Usage

### Complete Deployment

Deploy everything (recommended for first-time setup):
```bash
ansible-playbook -i inventory/staging playbooks/site.yml
```

### Provision Servers Only

Set up servers with base packages and Docker:
```bash
ansible-playbook -i inventory/staging playbooks/provision.yml
```

### Deploy Application Only

Deploy/update the application without touching infrastructure:
```bash
ansible-playbook -i inventory/staging playbooks/deploy.yml
```

### Deploy Monitoring Only

Set up or update monitoring stack:
```bash
ansible-playbook -i inventory/staging playbooks/monitoring.yml
```

### Deploy to Production

```bash
ansible-playbook -i inventory/production playbooks/site.yml
```

## Monitoring Access

After deployment, access monitoring tools:

### Prometheus
- URL: `http://YOUR_SERVER_IP:9090`
- Use Cases:
  - View metrics and time series data
  - Check alert status
  - Query metrics with PromQL
  - Verify target health

### Grafana
- URL: `http://YOUR_SERVER_IP:3100`
- Username: `admin` (default)
- Password: Set in `group_vars/all.yml` or environment variable
- Features:
  - Pre-configured dashboards
  - System overview dashboard
  - Custom dashboard creation
  - Alert visualization

### Node Exporter
- URL: `http://YOUR_SERVER_IP:9100/metrics`
- Provides system-level metrics

### cAdvisor
- URL: `http://YOUR_SERVER_IP:8080`
- Real-time container monitoring

## Alert Configuration

### Slack Integration (Optional)

To enable Slack alerts:

1. Create a Slack webhook URL
2. Set environment variable before running playbook:
   ```bash
   export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
   ansible-playbook -i inventory/staging playbooks/monitoring.yml
   ```

### Alert Rules

Pre-configured alerts in `roles/monitoring/templates/alert_rules.yml.j2`:

- **HighCPUUsage**: CPU > 80% for 5 minutes
- **HighMemoryUsage**: Memory > 85% for 5 minutes
- **DiskSpaceLow**: Disk space < 15%
- **ContainerDown**: Container unavailable for 2 minutes
- **BackendAPIDown**: API health check failing
- **HighResponseTime**: API p95 > 2 seconds

## Customization

### Adding Exporters

To monitor PostgreSQL or Redis:

1. Add exporters to `roles/monitoring/templates/docker-compose-monitoring.yml.j2`
2. Update Prometheus scrape configs in `roles/monitoring/templates/prometheus.yml.j2`
3. Redeploy monitoring:
   ```bash
   ansible-playbook -i inventory/staging playbooks/monitoring.yml
   ```

### Custom Dashboards

1. Create dashboard JSON files in `roles/monitoring/files/dashboards/`
2. Redeploy to provision new dashboards automatically

### Adjusting Alert Thresholds

Edit `roles/monitoring/templates/alert_rules.yml.j2` and update the alert expressions.

## Security Considerations

1. **Change Default Passwords**: Update all passwords in `group_vars/` files
2. **Use Ansible Vault**: Encrypt sensitive variables:
   ```bash
   ansible-vault encrypt group_vars/staging.yml
   ansible-playbook --ask-vault-pass -i inventory/staging playbooks/site.yml
   ```
3. **Restrict Monitoring Ports**: Use firewall rules or reverse proxy
4. **Enable HTTPS**: Configure Nginx reverse proxy for Grafana/Prometheus
5. **SSH Key Authentication**: Use SSH keys instead of passwords

## Troubleshooting

### Check Ansible Connectivity
```bash
ansible all -i inventory/staging -m ping
```

### Check Docker Status
```bash
ansible webservers -i inventory/staging -m command -a "docker ps"
```

### View Service Logs
```bash
# On the server
docker logs backend
docker logs prometheus
docker logs grafana
```

### Verify Monitoring Targets
- Open Prometheus: `http://YOUR_SERVER:9090/targets`
- All targets should show "UP" status

### Grafana Login Issues
Reset Grafana password:
```bash
docker exec -it grafana grafana-cli admin reset-admin-password newpassword
```

### Re-run Failed Tasks
```bash
ansible-playbook -i inventory/staging playbooks/site.yml --start-at-task="Task Name"
```

## Maintenance

### Update Application
```bash
# Update to latest code
ansible-playbook -i inventory/staging playbooks/deploy.yml
```

### Backup Monitoring Data
```bash
# Prometheus data
sudo tar -czf prometheus-backup-$(date +%Y%m%d).tar.gz /opt/monitoring/prometheus/data

# Grafana data
sudo tar -czf grafana-backup-$(date +%Y%m%d).tar.gz /opt/monitoring/grafana/data
```

### Clean Up Old Data
Prometheus automatically manages retention based on `prometheus_retention_days` (default: 15 days for staging, configurable per environment).

## Directory Structure

```
ansible/
├── ansible.cfg                 # Ansible configuration
├── inventory/                  # Server inventories
│   ├── staging
│   └── production
├── group_vars/                 # Variables per environment
│   ├── all.yml                 # Common variables
│   └── staging.yml             # Staging-specific vars
├── playbooks/                  # Orchestration playbooks
│   ├── site.yml                # Full deployment
│   ├── provision.yml           # Server setup
│   ├── deploy.yml              # App deployment
│   └── monitoring.yml          # Monitoring setup
└── roles/                      # Reusable roles
    ├── common/                 # Base server setup
    ├── docker/                 # Docker installation
    ├── app/                    # Application deployment
    └── monitoring/             # Monitoring stack
        ├── tasks/
        ├── templates/
        ├── files/
        │   └── dashboards/     # Grafana dashboards
        └── handlers/
```

## Integration with GitHub Actions

You can integrate this Ansible setup with your existing GitHub Actions workflow:

```yaml
- name: Deploy with Ansible
  env:
    ANSIBLE_HOST_KEY_CHECKING: False
  run: |
    cd ansible
    ansible-playbook -i inventory/staging playbooks/deploy.yml
```

## DevOps Teaching Notes

This Ansible setup demonstrates key DevOps practices:

1. **Infrastructure as Code**: All infrastructure defined in code
2. **Automation**: Repeatable, consistent deployments
3. **Monitoring**: Built-in observability from day one
4. **Idempotency**: Safe to run multiple times
5. **Modularity**: Reusable roles for different components
6. **Configuration Management**: Centralized variable management
7. **Health Checks**: Automated verification of deployment success

## Further Reading

- [Ansible Documentation](https://docs.ansible.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Docker Monitoring Best Practices](https://docs.docker.com/config/daemon/prometheus/)

## Support

For issues specific to this deployment:
1. Check the troubleshooting section above
2. Review Ansible output for specific error messages
3. Check service logs on the target server
4. Verify all prerequisites are met

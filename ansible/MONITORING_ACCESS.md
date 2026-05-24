# Monitoring Stack - Local Access Guide

## Deployment Success ✓

The complete monitoring stack has been successfully deployed to your local machine using Ansible!

## Access URLs

### Monitoring Services
- **Prometheus**: http://localhost:9090
  - Metrics database and query interface
  - View metrics, run queries, check targets
  
- **Grafana**: http://localhost:3100
  - **Username**: `admin`
  - **Password**: `changeme123`
  - Pre-configured with Prometheus datasource
  - System overview dashboard already loaded

- **Alertmanager**: http://localhost:9093
  - Alert routing and management
  - View active alerts and silences

### Metrics Exporters
- **Node Exporter**: http://localhost:9100/metrics
  - System-level metrics (CPU, memory, disk, network)
  
- **cAdvisor**: http://localhost:8080
  - Container metrics for all Docker containers
  - Container resource usage, performance stats

## Quick Start

### 1. Access Grafana Dashboard
```bash
# Open in browser
xdg-open http://localhost:3100
```

Login with `admin` / `changeme123` and navigate to:
- **Dashboards → System Overview** - Pre-configured dashboard with system metrics

### 2. Explore Prometheus
```bash
# Open Prometheus
xdg-open http://localhost:9090
```

Try these example queries:
```promql
# CPU usage
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Container CPU usage
rate(container_cpu_usage_seconds_total[5m]) * 100
```

### 3. Check Alert Rules
```bash
# View configured alerts
xdg-open http://localhost:9090/alerts

# View Alertmanager
xdg-open http://localhost:9093
```

## Management Commands

### Check Service Status
```bash
cd /home/juls/projects/pagasa-weather-demo/ansible
docker ps | grep -E "prometheus|grafana|node-exporter|cadvisor|alertmanager"
```

### View Logs
```bash
# Prometheus logs
docker logs prometheus

# Grafana logs
docker logs grafana

# All monitoring logs
docker logs prometheus && docker logs grafana && docker logs alertmanager
```

### Stop Monitoring Stack
```bash
cd /opt/monitoring
sudo docker-compose down
```

### Start Monitoring Stack
```bash
cd /opt/monitoring
sudo docker-compose up -d
```

### Restart Monitoring Stack
```bash
cd /opt/monitoring
sudo docker-compose restart
```

## Configuration Files

All configuration files are located in `/opt/monitoring/`:

```
/opt/monitoring/
├── docker-compose.yml           # Main compose file
├── prometheus/
│   ├── prometheus.yml          # Prometheus config
│   ├── alert_rules.yml         # Alert definitions
│   └── data/                   # Prometheus data (persistent)
├── alertmanager/
│   ├── alertmanager.yml        # Alert routing config
│   └── data/                   # Alertmanager data
└── grafana/
    ├── provisioning/           # Auto-provisioning configs
    │   ├── datasources/        # Prometheus datasource
    │   └── dashboards/         # Dashboard configs
    └── data/                   # Grafana data (persistent)
```

## Pre-configured Alerts

The following alerts are active:

### System Alerts
- ⚠️ **HighCPUUsage** - CPU usage > 80% for 5 minutes
- ⚠️ **HighMemoryUsage** - Memory usage > 85% for 5 minutes
- 🔴 **DiskSpaceLow** - Disk space < 15%

### Container Alerts
- 🔴 **ContainerDown** - Container not responding for 2 minutes
- ⚠️ **ContainerHighMemory** - Container memory > 90%
- ⚠️ **ContainerHighCPU** - Container CPU > 80%

### Application Alerts
- 🔴 **BackendAPIDown** - Health check failing for 2 minutes
- ⚠️ **HighResponseTime** - 95th percentile > 2 seconds
- 🔴 **DatabaseConnectionPoolExhausted** - Connection pool > 90%

## Troubleshooting

### Services not accessible?
```bash
# Check if containers are running
docker ps | grep -E "prometheus|grafana|alertmanager"

# Check Docker logs
docker logs prometheus
docker logs grafana

# Verify ports are not blocked
sudo netstat -tlnp | grep -E "9090|3100|9093"
```

### Grafana not loading dashboard?
```bash
# Check Grafana logs
docker logs grafana

# Restart Grafana
docker restart grafana
```

### No metrics showing?
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq

# Verify exporters are running
curl http://localhost:9100/metrics | head
curl http://localhost:8080/metrics | head
```

## Next Steps

### Monitor Your Application
The monitoring stack is collecting metrics from:
- ✓ System (CPU, memory, disk, network)
- ✓ Docker containers (resource usage)
- ✓ Application containers (pagasa-backend, pagasa-frontend, etc.)

### Add Custom Dashboards
1. Create new dashboards in Grafana UI
2. Export as JSON
3. Save to: `ansible/roles/monitoring/files/dashboards/`
4. Re-run playbook to deploy

### Configure Slack Alerts (Optional)
Edit `ansible/group_vars/all.yml`:
```yaml
slack_webhook_url: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

Then re-run the monitoring playbook:
```bash
cd /home/juls/projects/pagasa-weather-demo/ansible
ansible-playbook -i inventory/staging playbooks/monitoring.yml --ask-become-pass
```

## Deployment Details

### What Was Deployed
- ✅ Prometheus 2.50.1 - Metrics collection and storage
- ✅ Grafana 10.3.3 - Visualization and dashboards
- ✅ Node Exporter 1.7.0 - System metrics
- ✅ cAdvisor 0.49.1 - Container metrics
- ✅ Alertmanager (latest) - Alert management

### Deployment Method
- Infrastructure as Code with Ansible
- Containerized deployment with Docker Compose
- Persistent data volumes
- Pre-configured with best practices

### Time to Deploy
- ~2 minutes (after dependencies installed)

---

**Deployed**: $(date)
**Environment**: Local Development (staging)
**User**: juls
**Host**: staging-server (localhost)

## Manage the stack:
cd /opt/monitoring

# Stop
sudo docker-compose down

# Start
sudo docker-compose up -d

# Restart
sudo docker-compose restart

Re-deploy with Ansible:
cd /home/juls/projects/pagasa-weather-demo/ansible
ansible-playbook -i inventory/staging playbooks/monitoring.yml --ask-become-pass

## Access Your Dashboards
Grafana: http://localhost:3100 (admin / changeme123)

System Overview: http://localhost:3100/d/pagasa-system-overview
Application Monitoring: http://localhost:3100/d/pagasa-app-monitoring
Prometheus: http://localhost:9090

Exporters:

Backend metrics: http://localhost:8000/metrics
PostgreSQL: http://localhost:9187/metrics
Redis: http://localhost:9121/metrics

## Try These Queries in Prometheus
1. Check service status:
up{job=~"backend|postgres|redis"}

2. API request rate (requests per second):
rate(http_requests_total[5m])

3. Total requests by endpoint:
http_requests_total

4. API response time (95th percentile):
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

5. PostgreSQL active connections:
pg_stat_activity_count

6. Redis connected clients:
redis_connected_clients

7. System CPU usage:
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

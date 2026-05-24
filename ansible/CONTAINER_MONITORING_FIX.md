# Container Monitoring Fix Guide

## Issue Identified

Your containers are using Docker's **private cgroup namespace mode**, which prevents cAdvisor from exposing individual container metrics. This is a Docker security feature in recent versions.

**Diagnosis:**
```bash
docker inspect pagasa-backend | grep CgroupnsMode
# Output: "CgroupnsMode": "private"
```

This means cAdvisor can see overall Docker daemon metrics but not individual containers.

## Quick Solution Options

### Option 1: Use Docker Stats Command (Immediate)

You can monitor your containers right now using Docker's built-in command:

```bash
# Real-time stats
docker stats

# Or specific containers
docker stats pagasa-backend pagasa-frontend pagasa-postgres pagasa-redis
```

This shows live CPU, memory, network, and I/O for each container.

### Option 2: Modify Container Cgroup Mode (Requires Restart)

Add to your application's `docker-compose.yml`:

```yaml
services:
  backend:
    # ... existing config ...
    cgroup: host  # Allow cAdvisor to see this container
    
  frontend:
    # ... existing config ...
    cgroup: host
    
  postgres:
    # ... existing config ...
    cgroup: host
    
  redis:
    # ... existing config ...
    cgroup: host
```

Then restart:
```bash
cd /home/juls/projects/pagasa-weather-demo
docker-compose down
docker-compose up -d
```

**Security Note:** Using `cgroup: host` reduces container isolation slightly but allows proper monitoring.

### Option 3: Use Alternative Container Metrics

#### A) Docker Compose Exporter (Recommended)

Add this to your monitoring stack (`/opt/monitoring/docker-compose.yml`):

```yaml
  docker-compose-exporter:
    image: prometheuscommunity/docker-compose-exporter:latest
    container_name: docker-compose-exporter
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /home/juls/projects/pagasa-weather-demo:/docker-compose:ro
    command:
      - '--docker-compose-file=/docker-compose/docker-compose.yml'
    ports:
      - "9090:9090"  # Change to different port like 9091
    networks:
      - monitoring
```

Then add to Prometheus config (`/opt/monitoring/prometheus/prometheus.yml`):

```yaml
  - job_name: 'docker-compose'
    static_configs:
      - targets: ['docker-compose-exporter:9090']
```

#### B) Google cAdvisor Alternative (Latest Version)

Try the latest cAdvisor with better cgroup v2 support:

```bash
cd /opt/monitoring
# Update docker-compose.yml:
# Change: image: gcr.io/cadvisor/cadvisor:v0.49.1
# To:     image: gcr.io/cadvisor/cadvisor:latest

sudo docker-compose up -d cadvisor
```

## What's Currently Working

Even without per-container metrics, you DO have monitoring:

✅ **System-Level Metrics:**
- Overall CPU usage
- Total memory usage  
- Disk usage
- Network I/O

✅ **Aggregate Docker Metrics:**
- Total Docker daemon CPU
- Total Docker memory
- Docker buildkit stats

✅ **Application Health:**
- Containers are connected to monitoring network
- Can check health via: `curl http://pagasa-backend:8000/health`

## Recommended Immediate Actions

### 1. Fix the Dashboard to Show Working Metrics

The current dashboard is looking for `name` labels that don't exist. Update queries to use:

**For overall system:**
- CPU: `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
- Memory: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`

**For Docker aggregate:**
- Docker CPU: `rate(container_cpu_usage_seconds_total{id="/docker"}[5m])`
- Docker Memory: `container_memory_usage_bytes{id="/docker"}`

### 2. Add Application-Level Monitoring (Best Long-term Solution)

Instrument your backend to expose metrics. Add to `backend/requirements.txt`:

```
prometheus-client==0.19.0
```

Add to `backend/app/api/routes_health.py`:

```python
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response

# Metrics
request_count = Counter('http_requests_total', 'Total HTTP Requests', ['method', 'endpoint'])
request_duration = Histogram('http_request_duration_seconds', 'HTTP Request Duration')

@router.get("/metrics")
def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)
```

Then Prometheus can scrape: `http://pagasa-backend:8000/metrics`

### 3. Use Third-Party Exporters for Database/Redis

Add to your app's `docker-compose.yml`:

```yaml
  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    environment:
      DATA_SOURCE_NAME: "postgresql://pagasa:pagasa@pagasa-postgres:5432/pagasa_db?sslmode=disable"
    ports:
      - "9187:9187"
    networks:
      - pagasa-network
      - monitoring_monitoring  # Connect to monitoring network

  redis-exporter:
    image: oliver006/redis_exporter:latest
    environment:
      REDIS_ADDR: "pagasa-redis:6379"
    ports:
      - "9121:9121"
    networks:
      - pagasa-network
      - monitoring_monitoring
```

Update Prometheus targets from IP addresses to hostnames:

```yaml
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']
```

## Testing Steps

After applying any fix:

```bash
# 1. Check if metrics appear in Prometheus
curl 'http://localhost:9090/api/v1/query?query=up'

# 2. Check specific targets
open http://localhost:9090/targets

# 3. Test container queries
curl 'http://localhost:9090/api/v1/query?query=container_memory_usage_bytes'

# 4. Refresh Grafana dashboard
open http://localhost:3100/d/pagasa-system-overview
```

## Current Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| System Monitoring | ✅ Working | CPU, Memory, Disk, Network |
| Node Exporter | ✅ Working | System metrics available |
| cAdvisor | ⚠️ Partial | Sees Docker daemon, not individual containers |
| Prometheus | ✅ Working | Collecting available metrics |
| Grafana Dashboard | ⚠️ Broken Queries | Looking for non-existent labels |
| App Metrics | ❌ Not Configured | No /metrics endpoint |
| DB/Redis Metrics | ❌ Not Deployed | Exporters not added |

## Next Steps

**Choose one path:**

**Path A - Quick Fix (10 minutes):**
1. Run `docker stats` for now to see container metrics
2. Update dashboard queries to show system-level stats (working)
3. Add application instrumentation later

**Path B - Proper Fix (30 minutes):**
1. Add `cgroup: host` to docker-compose.yml
2. Restart containers
3. Wait for cAdvisor to discover them
4. Refresh Grafana

**Path C - Complete Solution (1 hour):**
1. Add application metrics endpoint
2. Add postgres & redis exporters
3. Update Prometheus configuration
4. Create proper dashboards
5. Configure alerts

## Commands Reference

```bash
# Check what cAdvisor sees
curl -s http://localhost:8080/metrics | grep container_cpu | head

# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | python3 -m json.tool

# View real-time container stats
docker stats --no-stream

# Restart monitoring stack
cd /opt/monitoring
sudo docker-compose restart

# Check container cgroup mode
docker inspect <container> | grep CgroupnsMode

# Connect container to monitoring network
docker network connect monitoring_monitoring <container-name>
```

##Files to Edit

1. **Application docker-compose.yml**: `/home/juls/projects/pagasa-weather-demo/docker-compose.yml`
2. **Monitoring compose**: `/opt/monitoring/docker-compose.yml`
3. **Prometheus config**: `/opt/monitoring/prometheus/prometheus.yml`
4. **Grafana dashboard**: Fix queries or import new dashboard

## Support

If you need help with any of these solutions, let me know which path you'd like to take!

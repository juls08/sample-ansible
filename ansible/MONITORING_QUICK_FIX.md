# Monitoring Stack - Quick Fix Applied ✓

## Issue Resolved

**Problem**: Dashboard wasn't loading in Grafana due to incorrect JSON structure  
**Solution**: Fixed dashboard JSON format (removed wrapper, added uid field)  
**Status**: ✅ Dashboard now visible in Grafana!

## Access Your Dashboard

**Grafana Dashboard**: http://localhost:3100/d/pagasa-system-overview

Login with:
- **Username**: `admin`
- **Password**: `changeme123`

The dashboard "PAGASA Weather Demo - System Overview" is now available!

## What's Currently Monitoring (Working ✓)

### System-Level Metrics
- **Node Exporter** - System metrics (CPU, memory, disk, network)
  - Status: ✅ UP
  - Metrics: http://localhost:9100/metrics
  
- **cAdvisor** - Container metrics for ALL Docker containers
  - Status: ✅ UP
  - UI: http://localhost:8080
  - Monitors: pagasa-backend, pagasa-frontend, pagasa-postgres, pagasa-redis

- **Prometheus** - Metrics collection
  - Status: ✅ UP
  - UI: http://localhost:9090
  - Targets: http://localhost:9090/targets

### Dashboard Panels Available Now
- System CPU Usage
- System Memory Usage  
- System Disk Usage
- Network I/O
- Container CPU & Memory (via cAdvisor)

## What's Not Yet Monitored (Optional)

### Application-Level Metrics (⚠️ Requires Code Changes)

The following targets are configured but not working:

1. **Backend API Metrics** (`/metrics` endpoint)
   - Status: ❌ DOWN
   - Reason: Backend doesn't expose `/metrics` endpoint
   - To fix: Add Prometheus instrumentation to FastAPI

2. **PostgreSQL Database Metrics**
   - Status: ❌ DOWN (exporter not deployed)
   - Reason: postgres_exporter container not included
   - Impact: Can't see database query performance, connections

3. **Redis Cache Metrics**
   - Status: ❌ DOWN (exporter not deployed)
   - Reason: redis_exporter container not included
   - Impact: Can't see cache hit rates, memory usage

4. **Docker Daemon Metrics**
   - Status: ❌ DOWN
   - Reason: Docker daemon metrics not enabled
   - Impact: Lower-level Docker stats (less critical with cAdvisor)

## Quick Test - See Your Containers Being Monitored

Open Prometheus and try these queries:

### Container CPU Usage
```promql
rate(container_cpu_usage_seconds_total{name=~"pagasa-.*"}[5m]) * 100
```

### Container Memory Usage (MB)
```promql
container_memory_usage_bytes{name=~"pagasa-.*"} / 1024 / 1024
```

### System CPU Usage
```promql
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### System Memory Usage (%)
```promql
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100
```

Go to: http://localhost:9090/graph and paste these queries!

## Option 1: Use What's Working (Recommended)

**Your containers ARE being monitored right now!** cAdvisor collects metrics from all Docker containers including your application. You can see:

- CPU usage per container
- Memory usage per container
- Network I/O per container
- Container restarts and status

This gives you visibility into your application's resource usage without code changes.

**View in Grafana**: The dashboard should show these metrics once data accumulates (give it 1-2 minutes).

## Option 2: Add Application-Level Monitoring (Advanced)

If you want deeper application metrics (request counts, response times, business metrics), you'll need to:

### 1. Instrument FastAPI Backend

Add to `backend/requirements.txt`:
```
prometheus-fastapi-instrumentator==6.1.0
```

Add to `backend/app/main.py`:
```python
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()

# Add this after creating the app
Instrumentator().instrument(app).expose(app)
```

Redeploy backend:
```bash
cd /home/juls/projects/pagasa-weather-demo
docker-compose restart backend
```

Test metrics:
```bash
curl http://localhost:8000/metrics
```

### 2. Add Database & Cache Exporters (Optional)

Add to your application's `docker-compose.yml`:

```yaml
  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    container_name: postgres-exporter
    environment:
      DATA_SOURCE_NAME: "postgresql://pagasa:pagasa@pagasa-postgres:5432/pagasa_db?sslmode=disable"
    ports:
      - "9187:9187"
    networks:
      - pagasa-network

  redis-exporter:
    image: oliver006/redis_exporter:latest
    container_name: redis-exporter
    environment:
      REDIS_ADDR: "pagasa-redis:6379"
    ports:
      - "9121:9121"
    networks:
      - pagasa-network
```

Restart stack:
```bash
docker-compose up -d
```

## Current Monitoring Capabilities

Even without application instrumentation, you currently have:

✅ **System Health**
- CPU, memory, disk, network usage
- Threshold alerts configured

✅ **Container Health**
- All your containers (backend, frontend, postgres, redis)
- Resource usage per container
- Container up/down status

✅ **Monitoring Stack Health**
- Prometheus collecting metrics
- Grafana visualizing data
- Alertmanager ready for alerts

✅ **Pre-configured Alerts**
- High CPU/Memory/Disk alerts
- Container down alerts
- Resource threshold warnings

## Next Steps

### Immediate (No Code Changes)
1. Open Grafana: http://localhost:3100/d/pagasa-system-overview
2. Refresh the page to see the dashboard
3. Wait 1-2 minutes for metrics to populate
4. Explore Prometheus: http://localhost:9090/targets

### Short-term (If You Want App Metrics)
1. Add Prometheus instrumentation to FastAPI (see Option 2 above)
2. Deploy postgres & redis exporters
3. Refresh Grafana - all targets will turn green!

### Long-term
1. Create custom dashboards for your specific metrics
2. Configure Slack alerts (set `slack_webhook_url` in group_vars)
3. Add business metrics (API calls, processing times, etc.)

## Troubleshooting

**Dashboard still not showing?**
```bash
# Refresh Grafana
docker restart grafana

# Check dashboard exists
curl -s -u admin:changeme123 http://localhost:3100/api/search?type=dash-db

# Should show: "PAGASA Weather Demo - System Overview"
```

**No data in panels?**
- Wait 1-2 minutes for metrics to accumulate
- Check Prometheus targets: http://localhost:9090/targets
- Verify node-exporter and cadvisor are UP (green)

**Want to see container metrics now?**
- Go to cAdvisor: http://localhost:8080
- Click on any container (pagasa-backend, pagasa-frontend, etc.)
- See live stats!

## Summary

✅ **Dashboard Fixed** - Now visible in Grafana  
✅ **System Monitoring** - Working perfectly  
✅ **Container Monitoring** - All containers tracked  
⚠️ **Application Metrics** - Optional, requires backend changes  

**You have a working monitoring stack!** The core infrastructure monitoring is operational and tracking all your containers. Application-level metrics are optional enhancements.

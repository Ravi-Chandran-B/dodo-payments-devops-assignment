# Task 3: Monitoring, Logging & Observability

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Observability Stack                 │
│                                                      │
│  Prometheus → collects metrics from all pods        │
│  Grafana    → visualizes metrics + logs             │
│  Loki       → stores and queries logs               │
│  Promtail   → collects logs from pods               │
│  Jaeger     → distributed tracing                   │
│  Alertmanager → sends alerts                        │
└─────────────────────────────────────────────────────┘
```

## Folder Structure

```
task3-observability/
├── prometheus/
│   ├── values.yaml     # Prometheus + Grafana config
│   └── alerts.yaml     # Alert rules
├── grafana/
│   └── dashboards/
│       └── dodo-dashboard.json  # Custom dashboard
├── loki/
│   └── values.yaml     # Loki + Promtail config
├── jaeger/
│   └── jaeger.yaml     # Jaeger deployment
├── install.sh          # Install everything
└── README.md
```

## Components

| Component | Purpose |
|-----------|---------|
| Prometheus | Metrics collection and storage |
| Grafana | Dashboards and visualization |
| Loki | Log aggregation |
| Promtail | Log collection from pods |
| Jaeger | Distributed tracing |
| Alertmanager | Alert routing |

## Installation

### Prerequisites
- EKS cluster running
- kubectl configured
- Helm installed

### Install All Components
```bash
cd task3-observability
chmod +x install.sh
./install.sh
```

### Manual Installation

#### 1. Create namespace
```bash
kubectl create namespace monitoring
```

#### 2. Install Prometheus + Grafana
```bash
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus/values.yaml
```

#### 3. Install Loki + Promtail
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install loki grafana/loki-stack \
  --namespace monitoring \
  --values loki/values.yaml
```

#### 4. Install Jaeger
```bash
kubectl apply -f jaeger/jaeger.yaml
```

#### 5. Apply Alert Rules
```bash
kubectl apply -f prometheus/alerts.yaml
```

## Access Dashboards

### Grafana
```bash
# Get URL
kubectl get svc monitoring-grafana -n monitoring

# Username: admin
# Password: admin123
```

### Jaeger
```bash
kubectl get svc jaeger -n monitoring
# Open: http://JAEGER_URL:16686
```

## Alert Rules

| Alert | Severity | Condition |
|-------|---------|-----------|
| PodCrashLooping | Critical | Pod restarts > 0 in 5 mins |
| PodNotReady | Warning | Pod not ready for 5 mins |
| HighCPUUsage | Warning | CPU > 80% for 5 mins |
| HighMemoryUsage | Warning | Memory > 85% for 5 mins |
| HighErrorRate | Critical | Error rate > 5% |
| HighLatency | Warning | P99 latency > 1s |

## SLOs and SLIs

| Service | SLI | SLO Target |
|---------|-----|-----------|
| Backend API | Error rate | < 1% errors |
| Backend API | Latency P99 | < 500ms |
| Backend API | Availability | > 99.9% uptime |
| Frontend | Availability | > 99.9% uptime |

## Verify Installation
```bash
# Check all pods running
kubectl get pods -n monitoring

# Check alert rules
kubectl get prometheusrule -n monitoring

# Check services
kubectl get svc -n monitoring
```

## Screenshots
See `screenshots/` folder for proof.

| Screenshot | Description |
|-----------|-------------|
| task3-grafana-dashboard.png | Grafana dashboard |
| task3-prometheus.png | Prometheus targets |
| task3-alerts.png | Alert rules |
| task3-grafana-kubernetes-dashboards.png | Grafana Kubernetes Dashboard |
| task3-grafana-namespace-pods.png | Grafana Pod name space |
| task3-prometheus-overview.png | Prometgeus Overview |
| task3-monitoring-services.png | Monitoring Service |
| task3-grafana-alert-rules.png | Grafana Alerts |
| task3-jaeger.png | Jaeger traces |

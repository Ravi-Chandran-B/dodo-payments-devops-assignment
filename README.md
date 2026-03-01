# Dodo Payments — DevOps & Security Engineer Assessment

## Overview

Complete implementation of the Dodo Payments DevOps & Security Engineer
technical assessment covering Kubernetes orchestration, CI/CD pipelines,
observability, security hardening, and Istio service mesh knowledge.

## Architecture

```
Internet
    │
    ▼
[AWS Load Balancer]
    │
    ▼
[EKS Cluster - us-east-1]
    ├── dodo-payments namespace
    │   ├── Frontend (React)    → LoadBalancer (public)
    │   ├── Backend (Node.js)   → ClusterIP (internal)
    │   └── PostgreSQL          → ClusterIP (internal)
    ├── argocd namespace        → GitOps auto-sync
    └── monitoring namespace    → Prometheus + Grafana + Loki + Jaeger

[GitHub] → push → [GitHub Actions] → build → [ECR] → deploy → [EKS]
[ArgoCD] → watches GitHub → auto-syncs → EKS
```

## Repository Structure

```
dodo-payments-devops-assignment/
├── .github/
│   └── workflows/
│       └── ci-cd.yml              # GitHub Actions pipeline
├── .yamllint                       # YAML lint config
├── README.md                       # This file
├── task1-kubernetes/               # EKS + microservices
│   ├── README.md
│   ├── terraform/                  # Infrastructure as Code
│   └── manifests/                  # Kubernetes manifests
│       ├── namespace.yaml
│       ├── configmap.yaml
│       ├── secret.yaml
│       ├── postgres.yaml
│       ├── backend.yaml
│       ├── frontend.yaml
│       ├── ingress.yaml
│       ├── hpa.yaml
│       └── pdb.yaml
│   └── app/
│       ├── backend/                # Node.js API
│       └── frontend/               # React app
├── task2-cicd/                     # CI/CD + ArgoCD
│   ├── README.md
│   └── argocd/
│       ├── application.yaml
│       └── install.sh
├── task3-observability/            # Monitoring stack
│   ├── README.md
│   ├── prometheus/
│   │   ├── values.yaml
│   │   └── alerts.yaml
│   ├── loki/
│   │   └── values.yaml
│   ├── jaeger/
│   │   └── jaeger.yaml
│   ├── grafana/
│   │   └── dashboards/
│   │       └── dodo-dashboard.json
│   ├── alerting/
│   │   └── slack-alerts.yaml
│   ├── runbooks/
│   │   └── runbook.md
│   └── install.sh
├── task4-security/                 # Security hardening
│   ├── README.md
│   ├── rbac.yaml
│   ├── network-policies.yaml
│   ├── pod-security.yaml
│   ├── sealed-secret.yaml
│   └── install.sh
└── task5-istio/                    # Istio knowledge assessment
    └── README.md
```

## Tasks Summary

| Task | Description | Status | Bonus |
|------|-------------|--------|-------|
| [Task 1](./task1-kubernetes/README.md) | Kubernetes + Microservices on EKS | ✅ Complete | 2/3 |
| [Task 2](./task2-cicd/README.md) | GitHub Actions + ArgoCD GitOps | ✅ Complete | 2/3 |
| [Task 3](./task3-observability/README.md) | Prometheus + Grafana + Loki + Jaeger | ✅ Complete | 2/3 |
| [Task 4](./task4-security/README.md) | RBAC + Network Policies + OPA | ✅ Complete | 0/3 |
| [Task 5](./task5-istio/README.md) | Istio Knowledge Assessment | ✅ Complete | - |

## Infrastructure Details

| Component | Details |
|-----------|---------|
| Cloud Provider | AWS (us-east-1) |
| Kubernetes | EKS v1.33 |
| Node Type | t3.medium x 3 |
| Container Registry | Amazon ECR |
| GitOps | ArgoCD |
| CI/CD | GitHub Actions |
| Monitoring | Prometheus + Grafana |
| Logging | Loki + Promtail |
| Tracing | Jaeger |

## Cost Considerations

| Resource | Cost/hour |
|----------|-----------|
| EKS Cluster | $0.10 |
| 3x t3.medium nodes | $0.125 |
| NAT Gateway | $0.045 |
| Load Balancers | ~$0.02 |
| **Total** | **~$0.29/hour** |

> Infrastructure destroyed after testing to minimize costs.
> Free-tier eligible resources used where possible.

## Quick Start

```bash
# 1. Deploy EKS infrastructure
cd task1-kubernetes/terraform
terraform init && terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig --name infra-eks --region us-east-1

# 3. Install ArgoCD (deploys app automatically)
cd task2-cicd/argocd && bash install.sh

# 4. Install monitoring stack
cd task3-observability && bash install.sh

# 5. Apply security hardening
cd task4-security && bash install.sh
```

## Screenshots

Screenshots of all working deployments are included in each task folder
under `screenshots/`.

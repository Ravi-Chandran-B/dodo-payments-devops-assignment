# Task 4: Security Hardening

## Overview

Comprehensive security measures across infrastructure and application layers
including RBAC, Network Policies, Sealed Secrets, and OPA Gatekeeper.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Security Layers                     │
│                                                      │
│  RBAC          → Who can do what in cluster         │
│  Network Policy → Which pod talks to which pod      │
│  Sealed Secrets → Encrypted secrets in Git          │
│  OPA Gatekeeper → Prevent insecure pods             │
│  Pod Security   → No privileged containers          │
└─────────────────────────────────────────────────────┘
```

## Folder Structure

```
task4-security/
├── rbac.yaml              # Roles for dev/operator/admin
├── network-policies.yaml  # Traffic restrictions
├── pod-security.yaml      # OPA Gatekeeper policies
├── sealed-secret.yaml     # Encrypted secrets template
├── install.sh             # Install everything
└── README.md
```

## Components

---

### 1. RBAC (Role-Based Access Control)

Three roles with least-privilege:

| Role | Can Do | Cannot Do |
|------|--------|-----------|
| Developer | View pods, logs, services | Create, delete, modify |
| Operator | View + restart + update | Delete namespace, manage secrets |
| Admin | Full access to namespace | Access other namespaces |

```bash
# Apply RBAC
kubectl apply -f rbac.yaml

# Verify roles
kubectl get roles -n dodo-payments
kubectl get rolebindings -n dodo-payments
```

---

### 2. Network Policies

Traffic is restricted between services:

```
Internet → Frontend (port 80) ✅
Frontend → Backend (port 3000) ✅
Backend  → PostgreSQL (port 5432) ✅

Internet → Backend ❌ BLOCKED
Internet → PostgreSQL ❌ BLOCKED
Frontend → PostgreSQL ❌ BLOCKED
```

```bash
# Apply network policies
kubectl apply -f network-policies.yaml

# Verify
kubectl get networkpolicies -n dodo-payments
```

---

### 3. Sealed Secrets

Secrets are encrypted and safe to store in Git!

```bash
# Install kubeseal
brew install kubeseal  # Mac
# or download from GitHub

# Install controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Create sealed secret
kubectl create secret generic app-secret \
  --namespace dodo-payments \
  --from-literal=DB_USER=$DB_USER \
  --from-literal=DB_PASSWORD=$DB_PASSWORD \
  --dry-run=client -o yaml | \
  kubeseal --format yaml > sealed-secret.yaml

# Apply (safe to commit!)
kubectl apply -f sealed-secret.yaml
```

---

### 4. OPA Gatekeeper Policies

Prevents insecure pod configurations:

| Policy | What it Prevents |
|--------|-----------------|
| No Privileged Containers | Containers cannot run as root |
| Read-only Root Filesystem | Containers cannot write to root |
| No Host Network | Containers cannot use host network |

```bash
# Install OPA Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.13.0/deploy/gatekeeper.yaml

# Apply policies
kubectl apply -f pod-security.yaml

# Verify
kubectl get constrainttemplates
```

---

### 5. Container Image Scanning

Already added in Task 2 CI/CD pipeline using Trivy:

```yaml
# From ci-cd.yml
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.ECR_REGISTRY }}/infra-eks-dev-backend:latest
    severity: 'CRITICAL,HIGH'
```

---

## Installation

### Install All Components
```bash
cd task4-security
chmod +x install.sh
./install.sh
```

### Verify Everything
```bash
# Check RBAC
kubectl get roles -n dodo-payments
kubectl get rolebindings -n dodo-payments

# Check Network Policies
kubectl get networkpolicies -n dodo-payments

# Check Sealed Secrets
kubectl get sealedsecrets -n dodo-payments

# Check OPA Policies
kubectl get constrainttemplates
kubectl get constraints
```

## Screenshots
See `screenshots/` folder for proof.

| Screenshot | Description |
|-----------|-------------|
| task4-rbac.png | RBAC roles listed |
| task4-network-policies.png | Network policies listed |
| task4-rolebindings.png | Rolebindings listed|
| task4-serviceaccounts.png | Service Accounts listed|

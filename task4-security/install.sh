#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────
# Task 4: Security Hardening Installation Script
# Run on Bastion EC2 after EKS is ready
# ─────────────────────────────────────────────────────────────────────────

set -e

echo "Installing Security Components..."

# ── STEP 1: Apply RBAC ───────────────────────────────────────────────────
echo "Applying RBAC roles..."
kubectl apply -f rbac.yaml
echo "✅ RBAC applied"

# ── STEP 2: Apply Network Policies ───────────────────────────────────────
echo "Applying Network Policies..."
kubectl apply -f network-policies.yaml
echo "✅ Network Policies applied"

# ── STEP 3: Install Sealed Secrets Controller ────────────────────────────
echo "Installing Sealed Secrets controller..."
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml
echo "✅ Sealed Secrets controller installed"

# ── STEP 4: Wait for Sealed Secrets controller ───────────────────────────
echo "Waiting for Sealed Secrets controller..."
kubectl wait --for=condition=available deployment/sealed-secrets-controller \
  -n kube-system --timeout=120s

# ── STEP 5: Install OPA Gatekeeper ──────────────────────────────────────
echo "Installing OPA Gatekeeper..."
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.13.0/deploy/gatekeeper.yaml
echo "✅ OPA Gatekeeper installed"

# ── STEP 6: Wait for Gatekeeper ─────────────────────────────────────────
echo "Waiting for OPA Gatekeeper..."
kubectl wait --for=condition=available deployment/gatekeeper-controller-manager \
  -n gatekeeper-system --timeout=180s

# ── STEP 7: Apply Pod Security Policies ─────────────────────────────────
echo "Applying Pod Security policies..."
kubectl apply -f pod-security.yaml
echo "✅ Pod Security policies applied"

# ── STEP 8: Create real Sealed Secret ───────────────────────────────────
echo ""
echo "Creating Sealed Secret for app credentials..."
kubectl create secret generic app-secret \
  --namespace dodo-payments \
  --from-literal=DB_USER=dodoadmin \
  --from-literal=DB_PASSWORD=dodopassword123 \
  --from-literal=POSTGRES_DB=dododb \
  --from-literal=POSTGRES_USER=dodoadmin \
  --from-literal=POSTGRES_PASSWORD=dodopassword123 \
  --dry-run=client -o yaml | \
  kubeseal --format yaml > sealed-secret-real.yaml

kubectl apply -f sealed-secret-real.yaml
echo "✅ Sealed Secret created and applied"

# ── STEP 9: Verify ───────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "✅ Security Hardening Complete!"
echo "========================================"
echo ""
echo "Verifying components..."
kubectl get roles -n dodo-payments
kubectl get networkpolicies -n dodo-payments
kubectl get sealedsecrets -n dodo-payments
kubectl get constrainttemplates
echo "========================================"
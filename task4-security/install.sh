#!/bin/bash
set -e

echo "Installing Security Components..."

echo "Applying RBAC roles..."
kubectl apply -f rbac.yaml
echo "RBAC applied"

echo "Applying Network Policies..."
kubectl apply -f network-policies.yaml
echo "Network Policies applied"

echo "Installing Sealed Secrets controller..."
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml
echo "Sealed Secrets controller installed"

echo "Waiting for Sealed Secrets controller..."
kubectl wait --for=condition=available deployment/sealed-secrets-controller \
  -n kube-system --timeout=120s

echo "Installing OPA Gatekeeper..."
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.13.0/deploy/gatekeeper.yaml
echo "OPA Gatekeeper installed"

echo "Waiting for OPA Gatekeeper..."
kubectl wait --for=condition=available deployment/gatekeeper-controller-manager \
  -n gatekeeper-system --timeout=180s


kubectl apply -f pod-security.yaml
echo "Pod Security policies applied"

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
echo "Sealed Secret created and applied"

echo ""
echo "========================================"
echo "Security Hardening Complete!"
echo "========================================"
echo ""
echo "Verifying components..."
kubectl get roles -n dodo-payments
kubectl get networkpolicies -n dodo-payments
kubectl get sealedsecrets -n dodo-payments
kubectl get constrainttemplates
echo "========================================"

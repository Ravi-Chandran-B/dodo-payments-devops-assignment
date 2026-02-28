#!/bin/bash
set -e

echo "Installing Observability Stack..."

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Namespace created"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
echo "✅ Helm repos added"

echo "Installing Prometheus + Grafana..."
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus/values.yaml \
  --wait \
  --timeout 10m
echo "✅ Prometheus + Grafana installed"

echo "Installing Loki + Promtail..."
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --values loki/values.yaml \
  --wait \
  --timeout 5m
echo "✅ Loki + Promtail installed"

echo "Installing Jaeger..."
kubectl apply -f jaeger/jaeger.yaml
echo "✅ Jaeger installed"

echo "Applying alert rules..."
kubectl apply -f prometheus/alerts.yaml
echo "✅ Alert rules applied"

echo "Waiting for pods to be ready..."
kubectl wait --for=condition=available deployment/monitoring-grafana \
  -n monitoring --timeout=300s

echo ""
echo "========================================"
echo "✅ Observability Stack Ready!"
echo "========================================"

GRAFANA_URL=$(kubectl get svc monitoring-grafana -n monitoring \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Grafana URL  : http://$GRAFANA_URL"
echo "Username     : admin"
echo "Password     : admin123"

JAEGER_URL=$(kubectl get svc jaeger -n monitoring \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Jaeger URL   : http://$JAEGER_URL:16686"
echo "========================================"
set -e

echo "Installing ArgoCD on EKS cluster..."

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD pods to be ready..."
kubectl wait --for=condition=available deployment/argocd-server \
  -n argocd --timeout=300s

kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "LoadBalancer"}}'

echo "Waiting for LoadBalancer IP..."
sleep 30
ARGOCD_URL=$(kubectl get svc argocd-server -n argocd \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ArgoCD URL: https://$ARGOCD_URL"

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD admin password: $ARGOCD_PASSWORD"
echo ""
echo "Login: https://$ARGOCD_URL"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"

echo "Deploying dodo-payments application..."
kubectl apply -f application.yaml

echo ""
echo "ArgoCD installation complete!"
echo "Application deployed and syncing..."
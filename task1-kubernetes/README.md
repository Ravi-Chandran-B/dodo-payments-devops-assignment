\# Task 1: Kubernetes Cluster Setup \& Microservices Deployment



\## Architecture

\- Frontend  : React app served via Nginx

\- Backend   : Node.js REST API

\- Database  : PostgreSQL



\## Infrastructure

\- Cloud     : AWS EKS

\- IaC       : Terraform

\- Region    : us-east-1



\## Kubernetes Resources

\- Namespace, ConfigMap, Secret

\- Deployments, Services, Ingress

\- HPA for Frontend and Backend

\- Resource limits and health probes



\## How to Deploy



\### 1. Create Infrastructure

```bash

cd terraform

terraform init

terraform apply

```



\### 2. Connect kubectl

```bash

aws eks update-kubeconfig --region us-east-1 --name dodo-payments-cluster

```



\### 3. Deploy Applications

```bash

kubectl apply -f manifests/namespace.yaml

kubectl apply -f manifests/configmap.yaml

kubectl apply -f manifests/secret.yaml

kubectl apply -f manifests/postgres.yaml

kubectl apply -f manifests/backend.yaml

kubectl apply -f manifests/frontend.yaml

kubectl apply -f manifests/ingress.yaml

kubectl apply -f manifests/hpa.yaml

```



\### 4. Verify

```bash

kubectl get nodes

kubectl get pods -n dodo-payments

kubectl get svc -n dodo-payments

```



\## Screenshots

See screenshots/ folder for proof of working deployment.


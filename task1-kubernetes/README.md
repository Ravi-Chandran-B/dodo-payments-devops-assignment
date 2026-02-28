# Task 1: Kubernetes Cluster Setup & Microservices Deployment

## Architecture

| Component | Technology |
|-----------|-----------|
| Frontend  | React app served via Nginx |
| Backend   | Node.js REST API |
| Database  | PostgreSQL |
| Cloud     | AWS EKS |
| IaC       | Terraform |
| Region    | us-east-1 |

## Folder Structure

```
task1-kubernetes/
├── terraform/          # AWS infrastructure as code
│   ├── main.tf         # Provider + S3 backend
│   ├── vpc.tf          # VPC, subnets, IGW, NAT
│   ├── eks.tf          # EKS cluster + node group
│   ├── ecr.tf          # ECR repositories
│   ├── iam.tf          # IAM roles
│   ├── bastion.tf      # Bastion EC2 host
│   ├── variable.tf     # Variables
│   └── output.tf       # Outputs
├── manifests/          # Kubernetes YAML files
│   ├── namespace.yaml  # dodo-payments namespace
│   ├── configmap.yaml  # App configuration
│   ├── secret.yaml     # DB credentials (template)
│   ├── postgres.yaml   # PostgreSQL deployment
│   ├── backend.yaml    # Backend deployment
│   ├── frontend.yaml   # Frontend deployment
│   ├── ingress.yaml    # Ingress rules
│   └── hpa.yaml        # Horizontal Pod Autoscaler
└── app/
    ├── frontend/       # React + Nginx
    └── backend/        # Node.js + Express
```

## Kubernetes Resources

- Namespace for isolation
- ConfigMap for non-sensitive configuration
- Secret for database credentials
- Deployments for all 3 services
- Services (ClusterIP for backend/DB, LoadBalancer for frontend)
- Ingress for traffic routing
- HPA for frontend and backend (scales on CPU > 70%)
- Resource requests and limits on all containers
- Liveness and readiness probes on all containers

## How to Deploy

### Prerequisites
- AWS CLI configured
- Terraform >= 1.0 installed
- kubectl installed
- Docker installed

### 1. Create Infrastructure
```bash
cd terraform
terraform init
terraform apply
```

### 2. Connect kubectl to EKS
```bash
aws eks update-kubeconfig --region us-east-1 --name infra-eks
```

### 3. Create Secret
```bash
# Set your values first
export DB_USER=your_username
export DB_PASSWORD=your_password
export POSTGRES_DB=dododb

kubectl create secret generic app-secret \
  --namespace dodo-payments \
  --from-literal=DB_USER=$DB_USER \
  --from-literal=DB_PASSWORD=$DB_PASSWORD \
  --from-literal=POSTGRES_DB=$POSTGRES_DB \
  --from-literal=POSTGRES_USER=$DB_USER \
  --from-literal=POSTGRES_PASSWORD=$DB_PASSWORD
```

### 4. Build and Push Docker Images
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
docker login --username AWS \
--password-stdin YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build and push frontend
cd app/frontend
docker build -t YOUR_ECR_FRONTEND_URL:latest .
docker push YOUR_ECR_FRONTEND_URL:latest

# Build and push backend
cd ../backend
docker build -t YOUR_ECR_BACKEND_URL:latest .
docker push YOUR_ECR_BACKEND_URL:latest
```

### 5. Deploy Applications
```bash
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/configmap.yaml
kubectl apply -f manifests/postgres.yaml
kubectl apply -f manifests/backend.yaml
kubectl apply -f manifests/frontend.yaml
kubectl apply -f manifests/ingress.yaml
kubectl apply -f manifests/hpa.yaml
```

### 6. Verify Deployment
```bash
# Check nodes
kubectl get nodes

# Check pods
kubectl get pods -n dodo-payments

# Check services
kubectl get svc -n dodo-payments

# Check HPA
kubectl get hpa -n dodo-payments
```

### 7. Access Application
```bash
# Get Load Balancer URL
kubectl get svc frontend-service -n dodo-payments
```
Open the EXTERNAL-IP in your browser!

## Screenshots
See `screenshots/` folder for proof of working deployment.

| Screenshot | Description |
|-----------|-------------|
| task1-nodes.png | EKS nodes in Ready state |
| task1-pods.png | All pods Running |
| task1-services.png | All services listed |
| task1-hpa.png | HPA configured |
| task1-app.png | Frontend app in browser |
| task1-ecr.png | Docker images in ECR |

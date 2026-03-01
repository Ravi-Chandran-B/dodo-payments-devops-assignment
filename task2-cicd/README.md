# Task 2: CI/CD Pipeline



# Overview



End-to-end CI/CD pipeline using GitHub Actions with ArgoCD for GitOps-based

deployments. Pipeline includes linting, security scanning, image building,

and automated Kubernetes deployment with rollback support.



# Pipeline Architecture



```

Developer pushes code

&nbsp;       │

&nbsp;       ▼

┌─────────────────────────────────────────────┐

│           GitHub Actions Pipeline            │

│                                             │

│  Job 1: Lint \& Test                         │

│    ├── yamllint on K8s manifests            │

│    ├── Backend npm test                     │

│    └── Frontend npm test                    │

│                                             │

│  Job 2: Security Scan (needs Job 1)         │

│    ├── Trivy scan backend source            │

│    └── Trivy scan frontend source           │

│                                             │

│  Job 3: Build \& Push (main branch only)     │

│    ├── Build backend Docker image           │

│    ├── Push to ECR (sha + latest tags)      │

│    ├── Build frontend Docker image          │

│    ├── Push to ECR (sha + latest tags)      │

│    ├── Trivy scan backend image             │

│    └── Trivy scan frontend image            │

│                                             │

│  Job 4: Deploy (needs Job 3)                │

│    ├── Configure kubectl (EKS)              │

│    ├── Create K8s secrets from GitHub       │

│    ├── Apply all manifests                  │

│    ├── Wait for rollout (300s)              │

│    ├── Rollback on failure ← auto!          │

│    └── Verify deployment                   │

└─────────────────────────────────────────────┘

&nbsp;       │

&nbsp;       ▼

┌─────────────────┐

│     ArgoCD      │ ← watches GitHub repo

│   (GitOps)      │ ← auto-syncs to EKS

│  self-heal: on  │ ← fixes manual changes

│  auto-prune: on │ ← removes deleted resources

└─────────────────┘

```



# Folder Structure



```

task2-cicd/

└── argocd/

&nbsp;   ├── application.yaml   # ArgoCD Application definition

&nbsp;   └── install.sh         # ArgoCD installation script



.github/

└── workflows/

&nbsp;   └── ci-cd.yml          # GitHub Actions pipeline



.yamllint                  # YAML lint configuration (root)

```



# Pipeline Jobs Detail



# Job 1: Lint and Test

\- Runs on: every push + every PR

\- yamllint validates all Kubernetes manifests

\- Backend: `npm install` + `npm test`

\- Frontend: `npm install` + `npm test --passWithNoTests`



# Job 2: Security Scan

\- Runs after: Job 1 passes

\- Trivy scans backend source for CRITICAL/HIGH vulnerabilities

\- Trivy scans frontend source for CRITICAL/HIGH vulnerabilities

\- exit-code: 0 (reports but does not block pipeline)



# Job 3: Build and Push

\- Runs on: main branch only

\- Tags images with git SHA + latest

\- Pushes to Amazon ECR

\- Trivy scans built images after push



# Job 4: Deploy

\- Runs after: Job 3 completes

\- Connects to EKS via AWS credentials

\- Creates Kubernetes secrets from GitHub Secrets

\- Applies all manifests

\- Waits 300s for rollout

\- Auto-rollback if deployment fails



# GitOps with ArgoCD



ArgoCD watches the GitHub repository and automatically syncs changes to EKS.



```yaml

syncPolicy:

&nbsp; automated:

&nbsp;   prune: true      # Remove deleted resources

&nbsp;   selfHeal: true   # Fix manual changes

```



\*\*Flow:\*\*

```

Git push → ArgoCD detects change → applies to cluster → verifies sync

```



# GitHub Secrets Required



| Secret | Description |

|--------|-------------|

| `AWS\_ACCESS\_KEY\_ID` | AWS IAM access key |

| `AWS\_SECRET\_ACCESS\_KEY` | AWS IAM secret key |

| `AWS\_ACCOUNT\_ID` | AWS account number |

| `DB\_USER` | PostgreSQL username |

| `DB\_PASSWORD` | PostgreSQL password |

| `POSTGRES\_DB` | PostgreSQL database name |



# Install ArgoCD



```bash

cd task2-cicd/argocd

bash install.sh

```



This script:

1\. Creates argocd namespace

2\. Installs ArgoCD via official manifests

3\. Exposes ArgoCD server via LoadBalancer

4\. Prints admin password

5\. Deploys dodo-payments application



# Rollback



\*\*Automatic rollback\*\* triggers on deployment failure:

```bash

kubectl rollout undo deployment/backend -n dodo-payments

kubectl rollout undo deployment/frontend -n dodo-payments

```



\*\*Manual rollback:\*\*

```bash

\# View history

kubectl rollout history deployment/backend -n dodo-payments



\# Rollback to previous version

kubectl rollout undo deployment/backend -n dodo-payments



\# Rollback to specific revision

kubectl rollout undo deployment/backend --to-revision=2 -n dodo-payments

```



# Automated Changelog (Bonus)



Changelog is auto-generated on each release using conventional commits.

See `.github/workflows/ci-cd.yml` for changelog generation step.



\## Screenshots

See `screenshots/` folder for proof.



| Screenshot | Description |

|-----------|-------------|

| task2-github-secrets.png | GitHub Screts |

| task2-pipeline-running.png | Pipeline Running|

| task2-pipeline-jobs.png | Pipeline Jobs |

| task2-argocd-pods.png | Argocd pods |

| task2-argocd-login.png | Argocd login |

| task2-argocd-dashboard.png | Argocd Dashboard |
| task2-argocd-app-synced.png | App synced |

| task2-argocd-app-tree.png | App tree |
| task2-argocd-full-tree.png | Argocd App Full Tree |
| task2-pipeline-history.png | Pipeline History |
| task2-pipeline-all-runs.png | Pipeline all Runs |


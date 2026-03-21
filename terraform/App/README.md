# Terraform App — ArgoCD Application for Helm Chart

Deploys ArgoCD Application that syncs the Helm chart from `applications/helm_chart` via public Git repository [Ryzhankou/Vyking](https://github.com/Ryzhankou/Vyking).

## Prerequisites

- ArgoCD installed (`make k8s-argocd-install`)
- Database deployed separately (`make helm-db-install`)
- Namespaces `game-frontend` and `game-backend` exist (created by Makefile targets)

## Usage

```bash
# From project root
make k8s-app-install ARGOCD_ADMIN_PASSWORD=<argocd-admin-password>
```

To get the ArgoCD admin password:

```bash
make k8s-argocd-password
```

## Uninstall

```bash
make k8s-app-uninstall ARGOCD_ADMIN_PASSWORD=<argocd-admin-password>
```

## Deployment Order

1. `make k8s-create` — create Kind cluster
2. `make k8s-argocd-install` — install ArgoCD
3. `make helm-db-install` — deploy database (separate from ArgoCD)
4. `make k8s-app-install` — deploy ArgoCD Application for app

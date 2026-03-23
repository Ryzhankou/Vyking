# Terraform

Terraform modules for Argo CD and GitOps deployment.

## Structure

| Directory | Purpose |
|-----------|---------|
| `ArgoCD/` | Installs Argo CD via Helm provider. Run: `make argocd-install` |
| `App/` | Creates root Argo CD Application `apps` (App of Apps). Run: `make app-install` |

## Deployment Order

1. `terraform/ArgoCD` — Install Argo CD first
2. `terraform/App` — Create root Application; Argo CD then syncs child apps from `argocd/apps/`

See [terraform/App/README.md](App/README.md) for App of Apps details.

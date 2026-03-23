# Terraform App — App of Apps

Creates a single root Argo CD Application (`apps`) that watches `argocd/apps/` in Git
and creates two child Applications from the manifests found there:

| Child App | Manifest | Path | Deploys | Sync Wave |
|-----------|----------|------|---------|-----------|
| `infrastructure` | `argocd/apps/infrastructure.yaml` | `infrastructure/mysql-chart` | MySQL (Bitnami) + backup CronJob | 0 |
| `myapp` | `argocd/apps/myapp.yaml` | `applications/helm_chart` | Frontend + Backend | 1 |

**Deployment order:** Wave 0 (`infrastructure`) must be healthy before wave 1 (`myapp`) starts.

## Branch / Target Revision

`make app-install` syncs the root App from the current git branch. Child apps use `HEAD`
(default branch). Push your branch before deploying, or use `main`:

```bash
make app-install ARGOCD_ADMIN_PASSWORD=<pwd> TARGET_REVISION=main
```

## Prerequisites

- Argo CD installed (`make argocd-install`)
- Namespaces `game-frontend` and `game-backend` (created automatically by Makefile)

## Usage

```bash
make kind-build-load
make app-install ARGOCD_ADMIN_PASSWORD=<password>
```

## Uninstall

```bash
make app-uninstall ARGOCD_ADMIN_PASSWORD=<password>
```

## Deployment Order

1. `make k8s-create` — create Kind cluster
2. `make argocd-install` — install Argo CD
3. `make kind-build-load` — build and load local images
4. `make app-install` — deploy root App of Apps (infrastructure → myapp)

# Terraform App — Argo CD Applications

Two modules create Argo CD Applications that sync from [Ryzhankou/Vyking](https://github.com/Ryzhankou/Vyking):

| Module | Application | Path | Deploys |
|--------|-------------|------|---------|
| `Infrastructure` | infrastructure | `infrastructure/mysql-chart` | MySQL (Bitnami) + backup CronJob |
| `App` | myapp | `applications/helm_chart` | Frontend + Backend |

**Deployment order:** Infrastructure deploys first, then App (via `depends_on`).

## Branch / Target Revision

By default, `make app-install` uses the **current git branch** for Argo CD sync.
The branch must be pushed to `origin` before deploying. Override:

```bash
make app-install ARGOCD_ADMIN_PASSWORD=<pwd> TARGET_REVISION=main
```

## Prerequisites

- Argo CD installed (`make argocd-install`)
- Namespaces `game-frontend` and `game-backend` (created automatically by Makefile)

## Usage

```bash
make app-install ARGOCD_ADMIN_PASSWORD=<password>
```

For Kind with local images:

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
4. `make app-install` — deploy both Argo CD Applications (infrastructure first, then app)

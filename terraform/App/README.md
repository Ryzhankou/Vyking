# Terraform App — Argo CD Applications

Two modules create Argo CD Applications that sync from [Ryzhankou/Vyking](https://github.com/Ryzhankou/Vyking):

| Module | Application | Path | Deploys |
|--------|-------------|------|---------|
| `Infrastructure` | infrastructure | `infrastructure/mysql-chart` | MySQL (Bitnami) + backup CronJob |
| `App` | myapp | `applications/helm_chart` | Frontend + Backend |

**Deployment order:** Infrastructure deploys first, then App (via `depends_on`).

## Branch / Target Revision

By default, `make k8s-app-install` uses the **current git branch** for Argo CD sync. Override:

```bash
make k8s-app-install ARGOCD_ADMIN_PASSWORD=<pwd> TARGET_REVISION=main
```

## Prerequisites

- Argo CD installed (`make k8s-argocd-install`)
- Namespaces `game-frontend` and `game-backend` (created by Makefile)

## Usage

```bash
make k8s-app-install ARGOCD_ADMIN_PASSWORD=<password>
```

For Kind with local images:

```bash
make kind-build-load
make k8s-app-install ARGOCD_ADMIN_PASSWORD=<password>
```

## Uninstall

```bash
make k8s-app-uninstall ARGOCD_ADMIN_PASSWORD=<password>
```

## Deployment Order

1. `make k8s-create` — create Kind cluster
2. `make k8s-argocd-install` — install Argo CD
3. `make k8s-app-install` — deploy both Argo CD Applications (infrastructure first, then app)

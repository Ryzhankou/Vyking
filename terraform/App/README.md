# Terraform App — Argo CD Applications

Creates two Argo CD Applications that sync from [Ryzhankou/Vyking](https://github.com/Ryzhankou/Vyking):

1. **infrastructure** — MySQL (Bitnami) + backup CronJob from `infrastructure/mysql-chart`
2. **myapp** — Frontend and backend from `applications/helm_chart`

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
3. `make k8s-app-install` — deploy both Argo CD Applications (infrastructure + app)

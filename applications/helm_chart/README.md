# Archer's Challenge Helm Chart

Deploys the Archer's Challenge game (frontend + backend) to Kubernetes. Used by Argo CD Application `myapp` (see `argocd/apps/myapp.yaml`).

## Architecture

- **Frontend**: `game-frontend` namespace, nodes with `tier: frontend`
- **Backend**: `game-backend` namespace, nodes with `tier: backend`
- **Database**: Deploy separately with `infrastructure/mysql-chart`

## Prerequisites

- Kubernetes cluster (>= 1.19) with nodes labeled `tier: frontend` and `tier: backend`
- Ingress controller (e.g. nginx-ingress) if using ingress
- Database deployed first (see infrastructure/mysql-chart)

## Deploy Database First

```bash
kubectl create namespace game-backend
helm dependency update infrastructure/mysql-chart
helm install infrastructure infrastructure/mysql-chart -n game-backend
```

Service name will be `infrastructure-archer-db` (release name + subchart alias).

## Deploy Application

```bash
# With Kind/local images (default uses FQDN for DB - works with App of Apps)
helm install myapp applications/helm_chart -n game-frontend --create-namespace -f applications/helm_chart/values-kind.yaml

# Same-namespace override (backend and MySQL both in game-backend)
helm install myapp applications/helm_chart -n game-frontend --create-namespace \
  -f applications/helm_chart/values-kind.yaml \
  --set backend.config.DB_HOST=infrastructure-archer-db
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `frontend.namespace` | Frontend namespace | `game-frontend` |
| `frontend.nodeSelector` | Node selector for frontend pods | `tier: frontend` |
| `backend.namespace` | Backend namespace | `game-backend` |
| `backend.nodeSelector` | Node selector for backend pods | `tier: backend` |
| `backend.config.DB_HOST` | MySQL host (use FQDN for cross-namespace) | `infrastructure-archer-db.game-backend.svc.cluster.local` |
| `backend.existingSecret.name` | Secret with DB_PASSWORD (key: mysql-password) | `infrastructure-archer-db` |

**Important**: `backend.config.DB_HOST` must resolve to MySQL. Use FQDN (`infrastructure-archer-db.game-backend.svc.cluster.local`) when backend and MySQL are in different namespaces (e.g. App of Apps). `backend.existingSecret.name` must match the infrastructure chart secret.

## Image Tags

For production, avoid `tag: "latest"`. Override with a specific version:

```bash
--set frontend.image.tag=1.2.3 --set backend.image.tag=1.2.3
```

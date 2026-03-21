# Archer's Challenge Helm Chart

Deploys the Archer's Challenge game (frontend + backend) to Kubernetes.

## Architecture

- **Frontend**: `game-frontend` namespace, nodes with `tier: frontend`
- **Backend**: `game-backend` namespace, nodes with `tier: backend`
- **Database**: Deploy separately with `applications/database-chart`

## Prerequisites

- Kubernetes cluster with nodes labeled `tier: frontend` and `tier: backend`
- Ingress controller (e.g. nginx-ingress)
- Database deployed first (see database-chart)

## Deploy Database First

```bash
# Add Bitnami repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Create namespace and deploy database
kubectl create namespace game-backend
helm dependency update applications/database-chart
helm install archer-db applications/database-chart -n game-backend
```

## Deploy Application

```bash
# Install app chart (creates game-frontend and game-backend namespaces)
helm install archer-game applications/helm_chart -n game-frontend --create-namespace

# Or with custom values
helm install archer-game applications/helm_chart -n game-frontend --create-namespace \
  -f values.yaml \
  --set backend.env.DB_HOST=archer-db-mysql
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `frontend.namespace` | Frontend namespace | `game-frontend` |
| `frontend.nodeSelector` | Node selector for frontend pods | `tier: frontend` |
| `backend.namespace` | Backend namespace | `game-backend` |
| `backend.nodeSelector` | Node selector for backend pods | `tier: backend` |
| `backend.env.DB_HOST` | MySQL service name | `archer-db-mysql` |

Ensure `backend.env.DB_HOST` matches the database release service name (e.g. `archer-db-mysql` when database is installed as `archer-db`).

# Vyking — Archer's Challenge

Kubernetes deployment with GitOps (Argo CD), Terraform, and Helm. Includes a multi-node Kind cluster, MySQL database with automated backups, and a frontend/backend application.

## Repository Structure

| Directory | Description |
|-----------|-------------|
| `applications/` | Custom Helm chart for frontend/backend, Dockerfiles |
| `infrastructure/` | MySQL (Bitnami) + backup CronJob Helm chart |
| `terraform/` | Argo CD installation + Argo CD Applications |
| `k8s/` | Kind config, Argo CD values |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.14
- [Helm](https://helm.sh/docs/intro/install/) (optional, for local testing)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Ryzhankou/Vyking.git
cd Vyking
```

### 2. Create the Cluster

```bash
make k8s-create
```

Verify the cluster:

```bash
kubectl get nodes -o wide
```

You should see 1 control-plane and 3 worker nodes.

### 3. Install Argo CD via Terraform

```bash
export ARGOCD_ADMIN_PASSWORD="YourSecurePassword"
export ARGOCD_ADMIN_PASSWORD_MTIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

make k8s-argocd-install
```

### 4. Deploy Argo CD Applications (Infrastructure + App)

This creates two Argo CD Applications that sync from this repository:

- **infrastructure**: MySQL (Bitnami) + backup CronJob
- **myapp**: Frontend and backend

```bash
make k8s-app-install ARGOCD_ADMIN_PASSWORD="$ARGOCD_ADMIN_PASSWORD"
```

For Kind with locally built images:

```bash
make kind-build-load
make k8s-app-install ARGOCD_ADMIN_PASSWORD="$ARGOCD_ADMIN_PASSWORD"
```

### 5. Access Argo CD UI

```bash
make k8s-argocd-port-forward
```

Open https://localhost:8080 (accept the self-signed certificate).

Get the admin password:

```bash
make k8s-argocd-password
```

Login: `admin` / `<password>`

You should see two applications: **infrastructure** and **myapp**. Both should sync automatically.

### 6. Verify Backup CronJob

Check that the CronJob runs and creates backups:

```bash
# List CronJob pods
kubectl get pods -n game-backend -l app=mysql-backup

# Exec into a backup pod to verify backup files
kubectl exec -n game-backend -it $(kubectl get pods -n game-backend -l app=mysql-backup -o jsonpath='{.items[0].metadata.name}') -- ls -la /backups
```

### 7. Access the Application

With Kind and local images:

```bash
# Port-forward frontend
kubectl port-forward -n game-frontend svc/myapp-frontend 8080:80
```

Open http://localhost:8080. The frontend should communicate with the backend; data persists in MySQL.

### 8. Clean Up

```bash
# Remove Argo CD Applications
make k8s-app-uninstall ARGOCD_ADMIN_PASSWORD="$ARGOCD_ADMIN_PASSWORD"

# Uninstall Argo CD
make k8s-argocd-uninstall

# Delete the cluster
make k8s-delete
```

## Deployment Flow

1. **k8s-create** — Creates Kind cluster (1 control-plane + 3 workers)
2. **k8s-argocd-install** — Installs Argo CD via Terraform Helm provider
3. **k8s-app-install** — Creates Argo CD Applications:
   - **infrastructure** → `infrastructure/mysql-chart` (Bitnami MySQL + backup CronJob)
   - **myapp** → `applications/helm_chart` (frontend + backend)

Argo CD syncs both applications from the Git repository.

## Backup CronJob

- **Schedule**: Every 5 minutes (for demo; adjust in `infrastructure/mysql-chart/values.yaml`)
- **Image**: `bitnami/mysql:8.0` (includes mysqldump)
- **Storage**: Dedicated PVC (`mysql-backup-pvc`)
- **Retention**: Backups older than 7 days are deleted
- **Secret**: MySQL password from Kubernetes Secret `archer-db`

## Makefile Targets

| Target | Description |
|--------|-------------|
| `k8s-create` | Create Kind cluster |
| `k8s-delete` | Delete Kind cluster |
| `k8s-argocd-install` | Install Argo CD via Terraform |
| `k8s-argocd-port-forward` | Port-forward Argo CD UI to 8080 |
| `k8s-argocd-password` | Show Argo CD admin password |
| `k8s-argocd-uninstall` | Uninstall Argo CD |
| `k8s-app-install` | Deploy Argo CD Applications |
| `k8s-app-uninstall` | Remove Argo CD Applications |
| `kind-build-load` | Build and load images into Kind |
| `helm-db-install` | Install MySQL via Helm (manual, non-GitOps) |
| `helm-app-install` | Install app via Helm (manual, non-GitOps) |
| `helm-app-install-kind` | Install app with local images (manual) |
| `k8s-fix-inotify` | Apply inotify limits workaround for "too many open files" |

## Troubleshooting

### MySQL: "too many open files" / fsnotify watcher errors

Kind nodes share the host kernel; inotify limits may be too low for MySQL and other workloads. If you see `unable to create fsnotify watcher: too many open files` or similar:

1. **New clusters**: `make k8s-create` applies the fix automatically.
2. **Existing clusters**: Run `make k8s-fix-inotify` to raise `fs.inotify.max_user_watches` and `fs.inotify.max_user_instances`.

## License

MIT

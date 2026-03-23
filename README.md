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
export ARGOCD_ADMIN_PASSWORD_MTIME=$(date -u -d '1 minute ago' +%Y-%m-%dT%H:%M:%SZ)

make argocd-install ARGOCD_ADMIN_PASSWORD="$ARGOCD_ADMIN_PASSWORD" ARGOCD_ADMIN_PASSWORD_MTIME="$ARGOCD_ADMIN_PASSWORD_MTIME"
```

### 4. Deploy Argo CD Applications (Infrastructure + App)

This creates two Argo CD Applications that sync from this repository:

- **infrastructure**: MySQL (Bitnami) + backup CronJob
- **myapp**: Frontend and backend

```bash
make infrastructure-install ARGOCD_ADMIN_PASSWORD="$ARGOCD_ADMIN_PASSWORD" ARGOCD_ADMIN_PASSWORD_MTIME="$ARGOCD_ADMIN_PASSWORD_MTIME"
make app-install ARGOCD_ADMIN_PASSWORD="$ARGOCD_ADMIN_PASSWORD" ARGOCD_ADMIN_PASSWORD_MTIME="$ARGOCD_ADMIN_PASSWORD_MTIME"
```

For Kind with locally built images:

```bash
make kind-build-load
make infrastructure-install ARGOCD_ADMIN_PASSWORD="$ARGOCD_ADMIN_PASSWORD" ARGOCD_ADMIN_PASSWORD_MTIME="$ARGOCD_ADMIN_PASSWORD_MTIME"
make app-install ARGOCD_ADMIN_PASSWORD="$ARGOCD_ADMIN_PASSWORD" ARGOCD_ADMIN_PASSWORD_MTIME="$ARGOCD_ADMIN_PASSWORD_MTIME"
```

### 5. Access Argo CD UI

```bash
make argocd-port-forward
```

Open https://localhost:8080 (accept the self-signed certificate).

Get the admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

Login: `admin` / `<password>`

You should see two applications: **infrastructure** and **myapp**. Both should sync automatically.

### 6. Verify Backup CronJob

Check that the CronJob runs and creates backups:

```bash
# List CronJob pods
kubectl get pods -n game-backend -l app.kubernetes.io/component=backup

# Exec into a backup pod to verify backup files
kubectl exec -n game-backend -it $(kubectl get pods -n game-backend -l app.kubernetes.io/component=backup -o jsonpath='{.items[0].metadata.name}') -- ls -la /backups
```

### 7. Access the Application

With Kind and local images:

```bash
# Port-forward frontend (service name: <release>-archer-game-frontend)
kubectl port-forward -n game-frontend svc/myapp-archer-game-frontend 8081:80
```

Open http://localhost:8081. The frontend proxies /api/ to the backend; data persists in MySQL.

### 8. Clean Up

```bash
# Remove Argo CD Applications
make app-uninstall ARGOCD_ADMIN_PASSWORD="$ARGOCD_ADMIN_PASSWORD" ARGOCD_ADMIN_PASSWORD_MTIME="$ARGOCD_ADMIN_PASSWORD_MTIME"
make infrastructure-uninstall ARGOCD_ADMIN_PASSWORD="$ARGOCD_ADMIN_PASSWORD" ARGOCD_ADMIN_PASSWORD_MTIME="$ARGOCD_ADMIN_PASSWORD_MTIME"

# Uninstall Argo CD
make argocd-uninstall ARGOCD_ADMIN_PASSWORD="$ARGOCD_ADMIN_PASSWORD" ARGOCD_ADMIN_PASSWORD_MTIME="$ARGOCD_ADMIN_PASSWORD_MTIME"

# Delete the cluster
make k8s-delete
```

## Deployment Flow

1. **k8s-create** — Creates Kind cluster (1 control-plane + 3 workers)
2. **argocd-install** — Installs Argo CD via Terraform Helm provider
3. **infrastructure-install** — Deploys infrastructure Argo CD Application (MySQL + backup CronJob)
4. **app-install** — Deploys applications Argo CD Application (frontend + backend)

Argo CD syncs both applications from the Git repository.

## Backup and Restore

**Backup CronJob**:
- **Schedule**: Every 5 minutes (for demo; adjust in `infrastructure/mysql-chart/values.yaml`)
- **Image**: `mysql:8.0` (includes mysqldump)
- **Storage**: Dedicated PVC (`infrastructure-backup-pvc`)
- **Retention**: Backups older than 7 days are deleted

**Restore** (via Makefile):
```bash
make mysql-list-backups           # List available backups
make mysql-restore                # Restore from latest backup
make mysql-restore BACKUP_FILE=gamedb_20250321_120000.sql.gz  # From specific file
```

## Makefile Targets

| Target | Description |
|--------|-------------|
| `k8s-create` | Create Kind cluster |
| `k8s-delete` | Delete Kind cluster |
| `argocd-install` | Install Argo CD via Terraform |
| `argocd-port-forward` | Port-forward Argo CD UI to 8080 |
| `argocd-uninstall` | Uninstall Argo CD |
| `infrastructure-install` | Deploy infrastructure Argo CD Application (MySQL + backup) |
| `infrastructure-uninstall` | Remove infrastructure application |
| `app-install` | Deploy applications Argo CD Application (frontend + backend) |
| `app-port-forward` | Port-forward frontend to 8081 |
| `app-uninstall` | Remove applications |
| `kind-build-load` | Build and load images into Kind |
| `mysql-list-backups` | List available MySQL backup files |
| `mysql-restore` | Restore MySQL from backup (optionally with `BACKUP_FILE=...`) |
| `up` | Full deployment: cluster + Argo CD + infrastructure + app |
| `down` | Full cleanup: app + infrastructure + Argo CD + cluster |

## Troubleshooting

### No data in Leaderboard / "Loading…" forever

1. **Check backend logs** (should show incoming requests):
   ```bash
   kubectl logs -n game-backend -l app.kubernetes.io/component=backend --tail=50 -f
   ```
   If you see no `Request: GET /api/leaderboard` — requests are not reaching the backend.

2. **Check MySQL has data**:
   ```bash
   kubectl exec -n game-backend infrastructure-archer-db-0 -- mysql -ugameuser -pgamepass gamedb -e "SELECT * FROM leaderboard LIMIT 5"
   ```

3. **Correct port-forward** (service name must match Argo CD release):
   ```bash
   kubectl port-forward -n game-frontend svc/myapp-archer-game-frontend 8081:80
   ```
   Then open http://localhost:8081 (F12 → Console shows `[Archer] fetch leaderboard: /api/leaderboard`).

4. **If MySQL empty** — either restore from backup or reset:
   ```bash
   make mysql-list-backups   # Check available backups
   make mysql-restore       # Restore from latest
   # Or reset: delete StatefulSet + PVC, let Argo CD recreate
   kubectl delete statefulset infrastructure-archer-db -n game-backend
   kubectl delete pvc data-infrastructure-archer-db-0 -n game-backend
   ```

### MySQL: "too many open files" / fsnotify watcher errors

Kind nodes share the host kernel; inotify limits may be too low for MySQL and other workloads. If you see `unable to create fsnotify watcher: too many open files` or similar:

1. **New clusters**: `make k8s-create` applies the fix automatically.
2. **Existing clusters**: Raise `fs.inotify.max_user_watches` and `fs.inotify.max_user_instances` on the host (e.g. via sysctl or Docker/Kind node config).

## License

MIT

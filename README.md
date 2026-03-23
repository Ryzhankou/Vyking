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

---

## Quick Start

Clone the repository and run a single command to deploy the full environment:

```bash
git clone https://github.com/Ryzhankou/Vyking.git
cd Vyking
make up ARGOCD_ADMIN_PASSWORD="YourSecurePassword"
```

To tear everything down:

```bash
make down ARGOCD_ADMIN_PASSWORD="YourSecurePassword"
```

> **Note**: Argo CD syncs from the remote Git repository using the current branch.
> Make sure your branch is pushed to `origin` before deploying.

---

## Makefile Targets

All steps are automated via `make`. Below is a description of each target and how to use it.

### Cluster

| Target | Description |
|--------|-------------|
| `k8s-create` | Create Kind cluster (1 control-plane + 3 workers). Skips if already running. Prints node info on completion. |
| `k8s-delete` | Delete the Kind cluster. |

```bash
make k8s-create
make k8s-delete
```

### Argo CD

| Target | Description |
|--------|-------------|
| `argocd-install` | Install Argo CD into the cluster via Terraform (Helm provider). |
| `argocd-port-forward` | Expose Argo CD UI at https://localhost:8080. Waits for pods to be ready. |
| `argocd-uninstall` | Remove Argo CD via Terraform. |

```bash
make argocd-install ARGOCD_ADMIN_PASSWORD="YourSecurePassword"
make argocd-port-forward
make argocd-uninstall ARGOCD_ADMIN_PASSWORD="YourSecurePassword"
```

### Applications

| Target | Description |
|--------|-------------|
| `kind-build-load` | Build local Docker images and load them into Kind nodes. |
| `app-install` | Deploy both Argo CD Applications (infrastructure + myapp) via a single `terraform apply`. |
| `app-port-forward` | Expose the frontend at http://localhost:8081. |
| `app-uninstall` | Remove both Argo CD Applications via Terraform. |

```bash
make kind-build-load
make app-install ARGOCD_ADMIN_PASSWORD="YourSecurePassword"
make app-port-forward
make app-uninstall ARGOCD_ADMIN_PASSWORD="YourSecurePassword"
```

> To deploy from a specific branch: `make app-install ARGOCD_ADMIN_PASSWORD=... TARGET_REVISION=main`

### Database

| Target | Description |
|--------|-------------|
| `mysql-list-backups` | List available backup files on the backup PVC. |
| `mysql-restore` | Restore MySQL from the latest backup (or a specific file). |

```bash
make mysql-list-backups
make mysql-restore
make mysql-restore BACKUP_FILE=gamedb_20250321_120000.sql.gz
```

---

## Verification

### 1. Cluster nodes

```bash
kubectl get nodes -o wide
```

You should see 1 control-plane and 3 worker nodes.

### 2. Argo CD UI

```bash
make argocd-port-forward
```

Open https://localhost:8080. Login: `admin` / `YourSecurePassword`.

You should see two applications: **infrastructure** and **myapp**, both synced and healthy.

### 3. Backup CronJob

Because CronJob pods terminate after completion, inspect the backup PVC via a temporary pod:

```bash
# Check that the CronJob is scheduled and Jobs are created
kubectl get cronjob -n game-backend
kubectl get jobs -n game-backend

# List backup files on the PVC
kubectl run backup-check -n game-backend --restart=Never --rm -it \
  --image=busybox \
  --overrides='{
    "spec": {
      "volumes": [{"name": "backups", "persistentVolumeClaim": {"claimName": "infrastructure-backup-pvc"}}],
      "containers": [{
        "name": "backup-check",
        "image": "busybox",
        "command": ["ls", "-lh", "/backups"],
        "volumeMounts": [{"name": "backups", "mountPath": "/backups"}]
      }]
    }
  }'
```

You should see timestamped `.sql.gz` files, e.g. `gamedb_20250321_120000.sql.gz`.

### 4. Frontend application

```bash
make app-port-forward
```

Open http://localhost:8081. The frontend proxies `/api/` to the backend; scores persist in MySQL.

---

## Backup and Restore

**Backup CronJob**:
- **Schedule**: Every 5 minutes (for demo; adjust in `infrastructure/mysql-chart/values.yaml`)
- **Image**: `mysql:8.0` (includes mysqldump)
- **Storage**: Dedicated PVC (`infrastructure-backup-pvc`)
- **Retention**: Backups older than 7 days are deleted automatically

**Restore**:
```bash
make mysql-list-backups           # List available backups
make mysql-restore                # Restore from latest backup
make mysql-restore BACKUP_FILE=gamedb_20250321_120000.sql.gz  # From specific file
```

---

## Troubleshooting

### No data in Leaderboard / "Loading…" forever

1. **Check backend logs**:
   ```bash
   kubectl logs -n game-backend -l app.kubernetes.io/component=backend --tail=50 -f
   ```

2. **Check MySQL has data**:
   ```bash
   kubectl exec -n game-backend infrastructure-archer-db-0 -- mysql -ugameuser -pgamepass gamedb -e "SELECT * FROM leaderboard LIMIT 5"
   ```

3. **Correct port-forward**:
   ```bash
   kubectl port-forward -n game-frontend svc/myapp-archer-game-frontend 8081:80
   ```

4. **If MySQL empty** — restore from backup or reset:
   ```bash
   make mysql-restore
   # Or reset: delete StatefulSet + PVC, let Argo CD recreate
   kubectl delete statefulset infrastructure-archer-db -n game-backend
   kubectl delete pvc data-infrastructure-archer-db-0 -n game-backend
   ```

### Argo CD fails to sync ("unable to resolve branch to a commit SHA")

The current branch is not pushed to origin:

```bash
git push origin $(git branch --show-current)
# Or deploy from main:
make app-install ARGOCD_ADMIN_PASSWORD="YourSecurePassword" TARGET_REVISION=main
```

### MySQL: "too many open files" / fsnotify watcher errors

Kind nodes share the host kernel; inotify limits may be too low. Fix on the host:

```bash
sudo sysctl -w fs.inotify.max_user_watches=524288
sudo sysctl -w fs.inotify.max_user_instances=512
```

To make it permanent, add to `/etc/sysctl.conf`:
```
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=512
```

## License

MIT

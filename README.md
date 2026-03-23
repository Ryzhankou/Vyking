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

### Option A — One command

```bash
git clone https://github.com/Ryzhankou/Vyking.git
cd Vyking
make up ARGOCD_ADMIN_PASSWORD="YourSecurePassword"
```

### Option B — Step by step

#### 1. Clone the Repository

```bash
git clone https://github.com/Ryzhankou/Vyking.git
cd Vyking
```

#### 2. Create the Cluster

```bash
make k8s-create
```

Node information is printed automatically after the cluster is ready (1 control-plane + 3 workers).

#### 3. Install Argo CD via Terraform

```bash
make argocd-install ARGOCD_ADMIN_PASSWORD="YourSecurePassword"
```

#### 4. Build and load images (Kind only)

```bash
make kind-build-load
```

#### 5. Deploy Argo CD Applications

A single `terraform apply` creates both Argo CD Applications that sync from this repository:

- **infrastructure**: MySQL (Bitnami) + backup CronJob
- **myapp**: Frontend and backend

```bash
make app-install ARGOCD_ADMIN_PASSWORD="YourSecurePassword"
```

> **Note**: Argo CD syncs from the remote Git repository using the current branch.
> Make sure the branch is pushed to `origin` before running this step:
> ```bash
> git push origin $(git branch --show-current)
> ```
> To use a specific branch: `make app-install ARGOCD_ADMIN_PASSWORD=... TARGET_REVISION=main`

#### 6. Access Argo CD UI

```bash
make argocd-port-forward
```

Open https://localhost:8080 (accept the self-signed certificate).

Login: `admin` / `YourSecurePassword`

You should see two applications: **infrastructure** and **myapp**. Both should sync automatically.

#### 7. Verify Backup CronJob

Check that the CronJob and its Jobs exist:

```bash
# Verify the CronJob is scheduled
kubectl get cronjob -n game-backend

# List Jobs created by the CronJob (runs every 5 minutes)
kubectl get jobs -n game-backend
```

Because CronJob pods terminate after completion, use a temporary pod to inspect the backup PVC directly:

```bash
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

#### 8. Access the Application

```bash
make app-port-forward
```

Open http://localhost:8081. The frontend proxies `/api/` to the backend; data persists in MySQL.

#### 9. Clean Up

```bash
make down ARGOCD_ADMIN_PASSWORD="YourSecurePassword"
```

Or step by step:

```bash
make app-uninstall ARGOCD_ADMIN_PASSWORD="YourSecurePassword"
make argocd-uninstall ARGOCD_ADMIN_PASSWORD="YourSecurePassword"
make k8s-delete
```

## Deployment Flow

1. **k8s-create** — Creates Kind cluster (1 control-plane + 3 workers)
2. **argocd-install** — Installs Argo CD via Terraform Helm provider
3. **kind-build-load** — Builds and loads local Docker images into Kind
4. **app-install** — Single `terraform apply` that deploys both Argo CD Applications:
   - **infrastructure**: MySQL (Bitnami) + backup CronJob
   - **myapp**: Frontend + backend

Argo CD syncs both applications from the Git repository.

## Backup and Restore

**Backup CronJob**:
- **Schedule**: Every 5 minutes (for demo; adjust in `infrastructure/mysql-chart/values.yaml`)
- **Image**: `mysql:8.0` (includes mysqldump)
- **Storage**: Dedicated PVC (`infrastructure-backup-pvc`)
- **Retention**: Backups older than 7 days are deleted automatically

**Restore** (via Makefile):
```bash
make mysql-list-backups           # List available backups
make mysql-restore                # Restore from latest backup
make mysql-restore BACKUP_FILE=gamedb_20250321_120000.sql.gz  # From specific file
```

## Makefile Targets

| Target | Description |
|--------|-------------|
| `k8s-create` | Create Kind cluster (skips if already running) |
| `k8s-delete` | Delete Kind cluster |
| `argocd-install` | Install Argo CD via Terraform |
| `argocd-port-forward` | Port-forward Argo CD UI to https://localhost:8080 |
| `argocd-uninstall` | Uninstall Argo CD |
| `kind-build-load` | Build local Docker images and load them into Kind |
| `app-install` | Deploy both Argo CD Applications via single `terraform apply` |
| `app-port-forward` | Port-forward frontend to http://localhost:8081 |
| `app-uninstall` | Remove both Argo CD Applications |
| `mysql-list-backups` | List available MySQL backup files |
| `mysql-restore` | Restore MySQL from backup (optionally with `BACKUP_FILE=...`) |
| `up` | Full deployment: cluster → Argo CD → images → apps |
| `down` | Full cleanup: apps → Argo CD → cluster |

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
   make mysql-restore        # Restore from latest
   # Or reset: delete StatefulSet + PVC, let Argo CD recreate
   kubectl delete statefulset infrastructure-archer-db -n game-backend
   kubectl delete pvc data-infrastructure-archer-db-0 -n game-backend
   ```

### Argo CD Applications fail to sync ("unable to resolve branch to a commit SHA")

Argo CD syncs from the remote Git repository. If the current branch has not been pushed:

```bash
git push origin $(git branch --show-current)
```

To deploy from `main` explicitly:

```bash
make app-install ARGOCD_ADMIN_PASSWORD="YourSecurePassword" TARGET_REVISION=main
```

### MySQL: "too many open files" / fsnotify watcher errors

Kind nodes share the host kernel; inotify limits may be too low for MySQL and other workloads. If you see `unable to create fsnotify watcher: too many open files` or similar, raise the limits on the host:

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

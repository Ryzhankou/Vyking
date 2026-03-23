# Infrastructure MySQL Chart

MySQL database (Bitnami) and backup CronJob for Archer's Challenge game. Deployed by Argo CD Application `infrastructure` (see `argocd/apps/infrastructure.yaml`).

## Architecture

- **MySQL**: Bitnami MySQL subchart (alias: archer-db), deploys to `game-backend` namespace
- **Init**: Custom ConfigMap with leaderboard table and seed data
- **Backup**: CronJob runs mysqldump to a dedicated PVC on schedule

## Prerequisites

- Kubernetes cluster (>= 1.19)
- StorageClass for PVCs (or use default)

## Install

**Via Argo CD** (recommended): Deployed automatically when `apps` root Application syncs.

**Manual Helm**:
```bash
helm dependency update infrastructure/mysql-chart
helm install infrastructure infrastructure/mysql-chart -n game-backend --create-namespace
```

Service: `infrastructure-archer-db`, Secret: `infrastructure-archer-db` (keys: `mysql-root-password`, `mysql-password`).

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `archer-db.auth.rootPassword` | Root password | `rootpassword` |
| `archer-db.auth.database` | Database name | `gamedb` |
| `archer-db.auth.username` | App user | `gameuser` |
| `archer-db.auth.password` | App password | `gamepass` |
| `archer-db.primary.persistence.size` | Data PVC size | `8Gi` |
| `backup.enabled` | Enable backup CronJob | `true` |
| `backup.schedule` | Cron schedule | `*/5 * * * *` |
| `backup.pvcSize` | Backup PVC size | `5Gi` |

## Restore from Backup

Standalone Jobs (applied via Makefile, not part of Helm release):

```bash
make mysql-list-backups           # List available backups (newest first)
make mysql-restore                # Restore from latest backup
make mysql-restore BACKUP_FILE=gamedb_20250321_120000.sql.gz  # Restore from specific file
```

Variables: `MYSQL_NS`, `MYSQL_RELEASE`, `MYSQL_BACKUP_PVC` (must match infrastructure helm release).

## Production

- Use `archer-db.auth.existingSecret` for root and app passwords
- Pin image tag (avoid `latest`)
- Adjust `backup.schedule` for production retention

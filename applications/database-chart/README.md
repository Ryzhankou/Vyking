# Archer's Challenge Database Chart

MySQL database for Archer's Challenge game. Deploys to `game-backend` namespace on backend nodes.

## Prerequisites

- Nodes labeled `tier: backend`

## Deploy

Uses official MySQL image (`mysql:8.0`), no subchart dependencies.

```bash
kubectl create namespace game-backend
helm install archer-db applications/database-chart -n game-backend
```

## Service Name

The MySQL service is named `archer-db-mysql` (release-name + chart-name). Configure the application backend with `DB_HOST: archer-db-mysql`.

## Backup CronJob

When `backup.enabled: true` (default), a CronJob runs `mysqldump` on a schedule:

- **Schedule**: Every 5 minutes (`*/5 * * * *`) for demonstration; override via `backup.schedule`
- **Image**: `mysql:8.0` (includes mysql-client/mysqldump)
- **Output**: `/backups/backup-YYYYMMDD-HHMMSS.sql` on a dedicated PVC
- **Credentials**: Fetched from the MySQL Secret (`mysql-password` key)

Configure in `values.yaml`:

```yaml
backup:
  enabled: true
  schedule: "*/5 * * * *"
  image:
    repository: mysql
    tag: "8.0"
  persistence:
    size: 2Gi
```

# Infrastructure

MySQL database and backup CronJob, deployed via Argo CD.

## Structure

- `mysql-chart/` — Helm chart with:
  - Bitnami MySQL subchart (alias: archer-db)
  - Init ConfigMap (schema + seed data)
  - Backup CronJob (mysqldump every 5 min)
  - Backup PVC

- `mysql-chart/templates/configmap-init.yaml` — Init ConfigMap with schema and seed data
- `mysql-chart/restore-job.yaml` — Standalone restore Job template (applied via `make mysql-restore`)

## Deployment

Deployed by Argo CD via **App of Apps**:
- Root Application `apps` (terraform/App) watches `argocd/apps/`
- Child Application `infrastructure` (`argocd/apps/infrastructure.yaml`) syncs `infrastructure/mysql-chart` to namespace `game-backend`

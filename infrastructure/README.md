# Infrastructure

MySQL database and backup CronJob, deployed via Argo CD Application `infrastructure`.

## Structure

- `mysql-chart/` — Helm chart with:
  - Bitnami MySQL dependency (Bitnami Helm chart)
  - Init ConfigMap (schema + seed data)
  - Backup CronJob (mysqldump every 5 min)
  - Backup PVC

- `Mysql/init.sql` — Source SQL for database initialization (used in ConfigMap)

## Deployment

Deployed by Argo CD Application defined in `terraform/App`. Syncs from `infrastructure/mysql-chart`.

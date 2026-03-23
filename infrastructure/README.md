# Infrastructure

MySQL database and backup CronJob, deployed via Argo CD Application `infrastructure`.

## Structure

- `mysql-chart/` — Helm chart with:
  - Bitnami MySQL dependency (Bitnami Helm chart)
  - Init ConfigMap (schema + seed data)
  - Backup CronJob (mysqldump every 5 min)
  - Backup PVC

- `mysql-chart/templates/configmap-init.yaml` — Init ConfigMap with schema and seed data (embedded SQL)

## Deployment

Deployed by Argo CD Application defined in `terraform/App`. Syncs from `infrastructure/mysql-chart`.

# Argo CD App of Apps Manifests

Child Application manifests watched by the root `apps` Application (created by `terraform/App`).

| File | App Name | Path | Namespace | Sync Wave |
|------|----------|------|-----------|-----------|
| `infrastructure.yaml` | `infrastructure` | `infrastructure/mysql-chart` | `game-backend` | 0 |
| `myapp.yaml` | `myapp` | `applications/helm_chart` | `game-frontend` | 1 |

## Deployment Order

Sync waves enforce that `infrastructure` (MySQL + backup CronJob) is healthy before
`myapp` (frontend + backend) starts deploying. This prevents the backend init container
from failing when MySQL is not yet ready.

## Notes

- **`infrastructure`** has no cascade finalizer — MySQL StatefulSet and PVC are preserved
  when the Application is deleted. This avoids a race condition during `make down`.
- **`myapp`** has `resources-finalizer.argocd.argoproj.io` — frontend/backend pods are
  cleaned up when the Application is deleted.
- Both apps use `targetRevision: HEAD` (default branch). Merge changes to `main` before
  deploying to ensure child apps pick up the latest Helm chart versions.

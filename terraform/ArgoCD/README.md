# Terraform ArgoCD — Argo CD Installation

Installs Argo CD into the Kind cluster via the Helm provider.

## Structure

```
terraform/ArgoCD/
├── main.tf          # Calls the ArgoCD module
├── variables.tf     # Input variables (password, namespace, chart config)
├── outputs.tf       # ArgoCD namespace output
├── providers.tf     # Helm provider configuration
└── modules/ArgoCD/
    ├── main.tf      # helm_release for argo-cd chart
    ├── locals.tf    # bcrypt hash of admin password
    ├── variables.tf
    ├── outputs.tf
    └── files/
        └── argocd-values.yaml  # nodeSelector (tier: main), service type ClusterIP
```

## Usage

```bash
make argocd-install ARGOCD_ADMIN_PASSWORD=<password>
make argocd-uninstall ARGOCD_ADMIN_PASSWORD=<password>
```

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `argocd_admin_password` | — | Admin password (bcrypt-hashed before passing to Helm) |
| `argocd_namespace` | `argocd` | Kubernetes namespace |
| `cluster_context` | `kind-dev-global-cluster-0` | Kubectl context |

## What it deploys

- Argo CD via [argoproj/argo-helm](https://github.com/argoproj/argo-helm) chart
- Admin password set at install time (bcrypt hash passed as Helm value)
- All ArgoCD pods scheduled on the node with label `tier: main`
- Service type: `ClusterIP` (access via `make argocd-port-forward`)

# Register the Git repository
resource "argocd_repository" "apps_repo" {
  repo = var.repo_url
}

# Register Bitnami Helm repository (required for MySQL subchart dependency)
resource "argocd_repository" "bitnami" {
  repo = "https://charts.bitnami.com/bitnami"
  type = "helm"
}

# Root "App of Apps" — watches argocd/apps/ in Git and creates child Applications.
# Deployment order is controlled by sync-wave annotations on the child manifests:
#   wave 0: infrastructure (MySQL + backup CronJob)
#   wave 1: myapp (frontend + backend)
resource "argocd_application" "root" {
  metadata {
    name      = "apps"
    namespace = "argocd"
  }

  # Wait for the root app (and therefore all child apps) to become healthy.
  # ArgoCD aggregates child Application health, so Terraform only returns
  # after MySQL, frontend, and backend are all running.
  wait = true

  spec {
    project = "default"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "argocd"
    }

    source {
      repo_url        = argocd_repository.apps_repo.repo
      path            = "argocd/apps"
      target_revision = var.target_revision
    }

    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }

      sync_options = ["CreateNamespace=true"]
    }
  }

  depends_on = [
    argocd_repository.apps_repo,
    argocd_repository.bitnami,
  ]
}

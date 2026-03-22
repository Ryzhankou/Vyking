# Infrastructure module: MySQL (Bitnami) + backup CronJob

resource "argocd_repository" "bitnami" {
  repo = "https://charts.bitnami.com/bitnami"
  type = "helm"
}

resource "argocd_project" "infrastructure" {
  metadata {
    name      = "infrastructure"
    namespace = "argocd"
  }

  spec {
    description = "Project for infrastructure (MySQL, backup CronJob)"

    source_repos = [
      var.repo_url,
      argocd_repository.bitnami.repo
    ]

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "game-backend"
    }

    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }

    namespace_resource_whitelist {
      group = "*"
      kind  = "*"
    }
  }
}

resource "argocd_application" "infrastructure" {
  metadata {
    name      = "infrastructure"
    namespace = "argocd"
  }

  wait = true

  spec {
    project = argocd_project.infrastructure.metadata[0].name

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "game-backend"
    }

    source {
      repo_url        = var.repo_url
      path            = "infrastructure/mysql-chart"
      target_revision = var.target_revision

      helm {
        release_name = "infrastructure"
      }
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
    argocd_repository.bitnami,
    argocd_project.infrastructure
  ]
}

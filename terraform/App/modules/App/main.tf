# Public Git repository (https://github.com/Ryzhankou/Vyking)
resource "argocd_repository" "apps_repo" {
  repo = "https://github.com/Ryzhankou/Vyking.git"
}

# Bitnami Helm repository (for MySQL chart dependency)
resource "argocd_repository" "bitnami" {
  repo = "https://charts.bitnami.com/bitnami"
  type = "helm"
}

# Infrastructure project: MySQL + backup CronJob
resource "argocd_project" "infrastructure" {
  metadata {
    name      = "infrastructure"
    namespace = "argocd"
  }

  spec {
    description = "Project for infrastructure (MySQL, backup CronJob)"

    source_repos = [
      argocd_repository.apps_repo.repo,
      "https://charts.bitnami.com/bitnami"
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

resource "argocd_project" "myapp" {
  metadata {
    name      = "myapp"
    namespace = "argocd"
  }

  spec {
    description = "Project for myapp"

    source_repos = [
      argocd_repository.apps_repo.repo
    ]

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "myapp"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "game-frontend"
    }
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

resource "argocd_application" "myapp" {
  metadata {
    name      = "myapp"
    namespace = "argocd"
  }

  wait = true

  spec {
    project = argocd_project.myapp.metadata[0].name

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "myapp"
    }

    source {
      repo_url        = argocd_repository.apps_repo.repo
      path            = "applications/helm_chart"
      target_revision = "main"

      helm {
        release_name = "myapp"
        value_files   = ["values-kind.yaml"]
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
    argocd_repository.apps_repo,
    argocd_project.myapp
  ]
}

# Infrastructure Argo CD Application: MySQL (Bitnami) + backup CronJob
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
      repo_url        = argocd_repository.apps_repo.repo
      path            = "infrastructure/mysql-chart"
      target_revision = "main"

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
    argocd_repository.apps_repo,
    argocd_repository.bitnami,
    argocd_project.infrastructure
  ]
}
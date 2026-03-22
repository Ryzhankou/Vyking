# Infrastructure module: MySQL + backup CronJob

resource "argocd_repository" "extra" {
  for_each = { for i, r in var.extra_helm_repos : r.repo => r }

  repo = each.value.repo
  type = each.value.type
}

locals {
  infrastructure_source_repos = concat(
    [var.repo_url],
    [for r in var.extra_helm_repos : r.repo]
  )
}

resource "argocd_project" "infrastructure" {
  metadata {
    name      = var.project_name
    namespace = "argocd"
  }

  spec {
    description = "Project for ${var.project_name} (MySQL, backup CronJob)"

    source_repos = local.infrastructure_source_repos

    destination {
      server    = var.destination_server
      namespace = var.destination_namespace
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

  depends_on = [argocd_repository.extra]
}

resource "argocd_application" "infrastructure" {
  metadata {
    name      = var.application_name
    namespace = "argocd"
  }

  wait = true

  spec {
    project = argocd_project.infrastructure.metadata[0].name

    destination {
      server    = var.destination_server
      namespace = var.destination_namespace
    }

    source {
      repo_url        = var.repo_url
      path            = var.helm_chart_path
      target_revision = var.target_revision

      helm {
        release_name = var.helm_release_name
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
    argocd_project.infrastructure
  ]
}

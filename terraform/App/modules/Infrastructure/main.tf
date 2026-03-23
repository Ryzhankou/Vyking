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

  # Do not wait for infrastructure health — the CronJob's backup Jobs would
  # block Terraform for minutes on every apply. MySQL readiness is verified
  # indirectly: the App module's wait=true + backend init container ensure
  # the stack is only considered healthy once MySQL is actually reachable.
  wait = false

  # Do not cascade-delete Kubernetes resources on destroy. MySQL StatefulSet
  # and PVC deletion is slow and causes a race condition where Terraform tries
  # to delete the ArgoCD project before the application is fully removed.
  # Data is preserved on redeploy; the Kind cluster is always deleted by
  # `make k8s-delete` anyway when running `make down`.
  cascade = false

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

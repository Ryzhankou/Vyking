resource "helm_release" "ArgoCD" {
  name             = "argocd"
  repository       = var.argocd_chart_repository
  chart            = var.argocd_chart_name
  namespace        = var.argocd_namespace
  wait             = true
  create_namespace = true

  values = [
    file("${path.module}/files/argocd-values.yaml")
  ]

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = local.argocd_admin_password_hash
  }

  set {
    name  = "configs.secret.argocdServerAdminPasswordMtime"
    value = var.argocd_admin_password_mtime
  }
}
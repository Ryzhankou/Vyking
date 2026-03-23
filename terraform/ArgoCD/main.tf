module "ArgoCD" {
  source = "./modules/ArgoCD"

  argocd_admin_password       = var.argocd_admin_password
  argocd_admin_password_mtime = var.argocd_admin_password_mtime
  argocd_namespace            = var.argocd_namespace
  argocd_chart_repository     = var.argocd_chart_repository
  argocd_chart_name           = var.argocd_chart_name
}
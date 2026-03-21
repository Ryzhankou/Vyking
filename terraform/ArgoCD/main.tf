module "ArgoCD" {
#   providers = {
#     # aws = aws.main
#     helm = helm
#   }
  source = "./modules/ArgoCD"

  argocd_admin_password       = var.argocd_admin_password
  argocd_admin_password_mtime = var.argocd_admin_password_mtime
}
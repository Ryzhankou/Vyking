locals {
  argocd_admin_password_hash = bcrypt(var.argocd_admin_password, 10)
}